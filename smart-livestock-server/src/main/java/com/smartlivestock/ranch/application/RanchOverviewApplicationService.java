package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.RanchOverviewDto;
import com.smartlivestock.ranch.application.dto.RanchOverviewDto.*;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.LivestockHealthState;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.HealthOverview;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RanchOverviewApplicationService {

    private final FenceRepository fenceRepository;
    private final LivestockRepository livestockRepository;
    private final AlertRepository alertRepository;
    private final HealthQueryPort healthQueryPort;
    private final IoTQueryPort ioTQueryPort;
    private final IdentityQueryPort identityQueryPort;

    @Transactional(readOnly = true)
    public RanchOverviewResponse getOverview(Long farmId) {
        // 1. Fences
        List<Fence> fences = fenceRepository.findByFarmId(farmId);
        List<FenceData> fenceDataList = fences.stream()
                .map(f -> new FenceData(
                        f.getId(),
                        f.getName(),
                        f.isActive(),
                        "POLYGON",
                        f.getColor(),
                        f.getVertices(),
                        0.0,
                        0,
                        f.getVersion()
                ))
                .toList();

        // 2. Livestock with health + GPS
        List<Livestock> livestockList = livestockRepository.findByFarmId(farmId);
        List<LivestockHealthState> healthStates = healthQueryPort.findHealthByFarmId(farmId);
        Map<Long, LivestockHealthState> healthMap = healthStates.stream()
                .collect(Collectors.toMap(LivestockHealthState::livestockId, h -> h, (a, b) -> a));

        List<LivestockMarker> markers = livestockList.stream()
                .filter(l -> l.getLastLatitude() != null && l.getLastLongitude() != null)
                .map(l -> {
                    var health = healthMap.get(l.getId());
                    String healthStatus = "NORMAL";
                    String primaryAlert = "";
                    if (health != null) {
                        healthStatus = deriveHealthStatus(health);
                        primaryAlert = derivePrimaryAlert(health);
                    }
                    return new LivestockMarker(
                            String.valueOf(l.getId()),
                            l.getLivestockCode(),
                            l.getLastLatitude(),
                            l.getLastLongitude(),
                            healthStatus,
                            primaryAlert
                    );
                })
                .toList();

        // 3. Alerts (non-archived)
        List<Alert> allAlerts = alertRepository.findByFarmId(farmId);
        List<AlertData> alertDataList = allAlerts.stream()
                .filter(a -> a.getStatus() != AlertStatus.ARCHIVED)
                .map(a -> new AlertData(
                        a.getId(),
                        a.getType().name(),
                        a.getSeverity().name(),
                        a.getStatus().name(),
                        a.getMessage(),
                        a.getLivestockId(),
                        a.getFenceId(),
                        null
                ))
                .toList();

        // 4. Health overview stats + scene summary
        HealthOverview healthOverview = healthQueryPort.getHealthOverview(farmId);

        double deviceOnlineRate = identityQueryPort.findFarmById(farmId)
                .map(f -> ioTQueryPort.getDeviceOnlineRate(f.tenantId()))
                .orElse(0.85);

        OverallStats overallStats = new OverallStats(
                healthOverview.totalLivestock(),
                healthOverview.healthyRate(),
                healthOverview.alertCount(),
                healthOverview.criticalCount(),
                deviceOnlineRate
        );

        SceneSummary sceneSummary = new SceneSummary(
                new SceneSummaryFever(
                        healthOverview.feverAbnormalCount(),
                        healthOverview.feverCriticalCount()),
                new SceneSummaryDigestive(
                        healthOverview.digestiveAbnormalCount(),
                        healthOverview.digestiveWatchCount()),
                new SceneSummaryEstrus(healthOverview.estrusHighScoreCount()),
                new SceneSummaryEpidemic(healthOverview.epidemicAbnormalRate())
        );

        // 5. Pending tasks derived from critical/warning livestock
        List<PendingTask> pendingTasks = new ArrayList<>();
        for (var l : livestockList) {
            var health = healthMap.get(l.getId());
            if (health == null) continue;

            String status = deriveHealthStatus(health);
            if ("CRITICAL".equals(status) || "WARNING".equals(status)) {
                pendingTasks.add(new PendingTask(
                        "task-" + l.getId(),
                        l.getLivestockCode() + " " + buildTaskTitle(health),
                        buildTaskSubtitle(health),
                        buildTaskRoute(health, l.getId()),
                        status
                ));
            }
        }

        return new RanchOverviewResponse(
                overallStats,
                sceneSummary,
                pendingTasks,
                fenceDataList,
                markers,
                alertDataList
        );
    }

    private String deriveHealthStatus(LivestockHealthState health) {
        if ("CRITICAL".equals(health.tempStatus())) return "CRITICAL";
        if ("FEVER".equals(health.tempStatus())) return "WARNING";
        if ("ABNORMAL".equals(health.motilityStatus())) return "WARNING";
        if ("ELEVATED".equals(health.tempStatus())) return "WARNING";
        if (health.estrusScore() >= 70) return "WARNING";
        return "NORMAL";
    }

    private String derivePrimaryAlert(LivestockHealthState health) {
        if ("CRITICAL".equals(health.tempStatus()) || "FEVER".equals(health.tempStatus())) return "FEVER";
        if ("ABNORMAL".equals(health.motilityStatus())) return "DIGESTIVE";
        if (health.estrusScore() >= 70) return "ESTRUS";
        return "";
    }

    private String buildTaskTitle(LivestockHealthState health) {
        if ("CRITICAL".equals(health.tempStatus()) || "FEVER".equals(health.tempStatus())) return "发热预警";
        if ("ABNORMAL".equals(health.motilityStatus())) return "消化异常";
        if (health.estrusScore() >= 70) return "发情高分";
        return "异常";
    }

    private String buildTaskSubtitle(LivestockHealthState health) {
        if ("CRITICAL".equals(health.tempStatus()) || "FEVER".equals(health.tempStatus())) return "体温异常需关注";
        if ("ABNORMAL".equals(health.motilityStatus())) return "蠕动异常需观察";
        if (health.estrusScore() >= 70) return "发情评分 " + health.estrusScore();
        return "";
    }

    private String buildTaskRoute(LivestockHealthState health, Long livestockId) {
        if ("CRITICAL".equals(health.tempStatus()) || "FEVER".equals(health.tempStatus())) return "/twin/fever/" + livestockId;
        if ("ABNORMAL".equals(health.motilityStatus())) return "/twin/digestive/" + livestockId;
        if (health.estrusScore() >= 70) return "/twin/estrus/" + livestockId;
        return "";
    }
}
