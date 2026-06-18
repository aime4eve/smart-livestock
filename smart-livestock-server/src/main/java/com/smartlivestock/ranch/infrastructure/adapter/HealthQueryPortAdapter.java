package com.smartlivestock.ranch.infrastructure.adapter;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class HealthQueryPortAdapter implements HealthQueryPort {

    private final HealthSnapshotRepository snapshotRepository;
    private final RanchQueryPort ranchQueryPort;

    @Override
    public Optional<LivestockHealthState> findHealthByLivestockId(Long livestockId) {
        return snapshotRepository.findByLivestockId(livestockId)
                .map(s -> new LivestockHealthState(
                        s.getLivestockId(),
                        statusString(s.getTempStatus()),
                        statusString(s.getMotilityStatus()),
                        s.getEstrusScore() != null ? s.getEstrusScore() : 0,
                        s.getCurrentTemp(),
                        s.getCurrentMotility(),
                        s.getActivityStatus() != null ? s.getActivityStatus().name() : "NORMAL"
                ));
    }

    @Override
    public List<LivestockHealthState> findHealthByFarmId(Long farmId) {
        return snapshotRepository.findByFarmId(farmId).stream()
                .map(s -> new LivestockHealthState(
                        s.getLivestockId(),
                        statusString(s.getTempStatus()),
                        statusString(s.getMotilityStatus()),
                        s.getEstrusScore() != null ? s.getEstrusScore() : 0,
                        s.getCurrentTemp(),
                        s.getCurrentMotility(),
                        s.getActivityStatus() != null ? s.getActivityStatus().name() : "NORMAL"
                ))
                .toList();
    }

    @Override
    public HealthOverview getHealthOverview(Long farmId) {
        List<HealthSnapshot> snapshots = snapshotRepository.findByFarmId(farmId);
        int total = ranchQueryPort.findAllByFarmId(farmId).size();
        int alertCount = ranchQueryPort.countActiveAlertsByFarmId(farmId);

        long healthyCount = snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.NORMAL
                        && s.getMotilityStatus() == MotilityStatus.NORMAL)
                .count();
        double healthyRate = total > 0 ? (double) healthyCount / total : 1.0;

        int criticalCount = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.CRITICAL)
                .count();

        int feverAbnormal = (int) snapshots.stream()
                .filter(s -> s.getTempStatus() == TempStatus.FEVER || s.getTempStatus() == TempStatus.CRITICAL)
                .count();
        int feverCritical = criticalCount;

        int digestiveAbnormal = (int) snapshots.stream()
                .filter(s -> s.getMotilityStatus() == MotilityStatus.ABNORMAL)
                .count();
        int digestiveWatch = (int) snapshots.stream()
                .filter(s -> s.getMotilityStatus() == MotilityStatus.LOW)
                .count();

        int estrusHighScore = (int) snapshots.stream()
                .filter(s -> s.getEstrusScore() != null && s.getEstrusScore() >= 70)
                .count();

        double epidemicAbnormalRate = total > 0
                ? (double) snapshots.stream()
                        .filter(s -> s.getTempStatus() != TempStatus.NORMAL
                                || s.getMotilityStatus() != MotilityStatus.NORMAL)
                        .count() / total
                : 0.0;

        return new HealthOverview(
                total, Math.round(healthyRate * 1000.0) / 1000.0,
                alertCount, criticalCount,
                feverAbnormal, feverCritical,
                digestiveAbnormal, digestiveWatch,
                estrusHighScore,
                Math.round(epidemicAbnormalRate * 1000.0) / 1000.0
        );
    }

    private String statusString(Enum<?> status) {
        return status != null ? status.name() : "NORMAL";
    }
}
