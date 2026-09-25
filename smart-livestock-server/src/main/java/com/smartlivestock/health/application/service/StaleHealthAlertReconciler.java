package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Hourly self-healing for stale health tickets (NIX-245): a livestock whose
 * snapshot state recovered but whose ticket stayed ACTIVE (lost transition,
 * e.g. restarts) breaks the "abnormal cattle == open tickets" reconciliation.
 * This reconciler resolves such tickets using the same state mapping as the
 * health alert bridge (all sources of that type — if the state is normal
 * again, any ticket of that type is stale).
 */
@Slf4j
@Service
public class StaleHealthAlertReconciler {

    static final Set<String> HEALTH_TYPES = Set.of(
            "TEMPERATURE_ABNORMAL", "DIGESTIVE_ABNORMAL", "ESTRUS");

    private final HealthSnapshotRepository snapshotRepo;
    private final RanchQueryPort ranchQueryPort;
    private final RanchCommandPort ranchCommandPort;

    @Value("${health.alert-reconcile.enabled:true}")
    private boolean enabled;

    public StaleHealthAlertReconciler(HealthSnapshotRepository snapshotRepo,
                                      RanchQueryPort ranchQueryPort,
                                      RanchCommandPort ranchCommandPort) {
        this.snapshotRepo = snapshotRepo;
        this.ranchQueryPort = ranchQueryPort;
        this.ranchCommandPort = ranchCommandPort;
    }

    @Scheduled(cron = "${health.alert-reconcile.cron:0 40 * * * *}")
    public void reconcileAllFarms() {
        if (!enabled) return;
        for (Long farmId : snapshotRepo.findDistinctFarmIds()) {
            try {
                int resolved = reconcileFarm(farmId);
                if (resolved > 0) {
                    log.info("Stale health ticket reconcile for farm [{}]: resolved {} tickets", farmId, resolved);
                }
            } catch (Exception e) {
                log.warn("Stale health ticket reconcile failed for farm [{}]: {}", farmId, e.getMessage());
            }
        }
    }

    public int reconcileFarm(Long farmId) {
        List<AlertBrief> active = ranchQueryPort
                .findActiveAlertsByFarmIdAndTypes(farmId, HEALTH_TYPES);
        if (active.isEmpty()) return 0;

        Map<Long, HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId).stream()
                .collect(Collectors.toMap(HealthSnapshot::getLivestockId, Function.identity(), (a, b) -> a));

        int resolved = 0;
        for (AlertBrief alert : active) {
            if (alert.livestockId() == null) continue; // farm-level tickets managed elsewhere
            Optional<HealthSnapshot> snap = Optional.ofNullable(snapshots.get(alert.livestockId()));
            if (snap.isEmpty()) continue;              // cannot judge → leave the ticket alone
            if (stateRecovered(alert.type(), snap.get())) {
                ranchCommandPort.resolveAlert(alert.livestockId(), alert.type());
                resolved++;
            }
        }
        return resolved;
    }

    private boolean stateRecovered(String alertType, HealthSnapshot snap) {
        return switch (alertType) {
            case "TEMPERATURE_ABNORMAL" -> snap.getTempStatus() == TempStatus.NORMAL;
            case "DIGESTIVE_ABNORMAL" -> snap.getMotilityStatus() != MotilityStatus.ABNORMAL;
            case "ESTRUS" -> snap.getEstrusScore() == null || snap.getEstrusScore() < 70;
            default -> false;
        };
    }
}
