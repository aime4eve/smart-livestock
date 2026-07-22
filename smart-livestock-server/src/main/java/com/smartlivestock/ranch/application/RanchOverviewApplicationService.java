package com.smartlivestock.ranch.application;

import com.smartlivestock.ranch.application.dto.RanchOverviewDto;
import com.smartlivestock.ranch.application.dto.RanchOverviewDto.*;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.LivestockHealthState;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.HealthOverview;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import com.smartlivestock.shared.cache.RedisCacheService;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Duration;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.Set;
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
    private final SpringDataAlertReadStatusRepository readStatusRepository;
    private final FenceZoneRepository fenceZoneRepository;
    private final RedisCacheService redisCacheService;
    private final ObjectMapper objectMapper;


    @Transactional(readOnly = true)
    public RanchOverviewResponse getOverview(Long farmId, Long userId, Long tenantId) {
        // 0. Short-TTL Redis cache to absorb polling bursts (30s timer) and concurrent viewers.
        String cacheKey = "ranch:overview:" + farmId + ":" + userId;
        try {
            String cached = redisCacheService.get(cacheKey);
            if (cached != null) {
                return objectMapper.readValue(cached, RanchOverviewResponse.class);
            }
        } catch (Exception ignored) {
            // Cache miss or deserialization error — fall through to DB query
        }

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

        // 3. Alerts (active only)
        List<Alert> allAlerts = alertRepository.findByFarmId(farmId);
        List<Alert> activeAlerts = allAlerts.stream()
                .filter(a -> a.getStatus() == AlertStatus.ACTIVE)
                .toList();
        Set<Long> readAlertIds = userId != null && !activeAlerts.isEmpty()
                ? readStatusRepository.findReadAlertIdsByUserId(userId,
                        activeAlerts.stream().map(Alert::getId).toList())
                : Set.of();
        List<AlertData> alertDataList = activeAlerts.stream()
                .map(a -> new AlertData(
                        a.getId(),
                        a.getType().name(),
                        a.getSeverity().name(),
                        a.getStatus().name(),
                        a.getMessage(),
                        a.getLivestockId(),
                        a.getFenceId(),
                        null,
                        readAlertIds.contains(a.getId()),
                        a.getResolvedType(),
                        a.getResolvedAt(),
                        null,
                        null
                ))
                .toList();

        // 4. Alert summaries grouped by type (ACTIVE only)
        Map<String, Integer> fenceAlertSummary = buildFenceAlertSummary(allAlerts);
        Map<String, Integer> healthAlertSummary = buildHealthAlertSummary(allAlerts);

        // Reuse the already-loaded livestock/health/alerts data instead of re-querying
        // (getHealthOverview would re-fetch snapshots, livestock, and alerts a second time).
        HealthOverview healthOverview = buildHealthOverview(livestockList, healthStates, activeAlerts);
        double deviceOnlineRate = tenantId != null
                ? ioTQueryPort.getDeviceOnlineRate(tenantId)
                : 0.85;

        // 6. InFenceRate: livestock inside any fence / livestock with GPS
        Double inFenceRate = calculateInFenceRate(livestockList, fences);

        OverallStats overallStats = new OverallStats(
                healthOverview.totalLivestock(),
                healthOverview.healthyRate(),  // Double (nullable)
                healthOverview.alertCount(),
                healthOverview.criticalCount(),
                deviceOnlineRate,
                inFenceRate
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

        // 7. Pending tasks derived from critical/warning livestock
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

        RanchOverviewResponse response = new RanchOverviewResponse(
                overallStats,
                sceneSummary,
                pendingTasks,
                fenceDataList,
                markers,
                alertDataList,
                fenceAlertSummary,
                healthAlertSummary,
                fenceZoneRepository.findByFarmId(farmId).stream().map(FenceZoneData::from).toList()
        );

        try {
            redisCacheService.set(cacheKey, objectMapper.writeValueAsString(response),
                    Duration.ofSeconds(10));
        } catch (Exception ignored) {
            // Cache write failure is non-critical
        }

        return response;
    }

    /**
     * Calculate inFenceRate: count of livestock inside any active fence / total with GPS.
     */
    private Double calculateInFenceRate(List<Livestock> livestockList, List<Fence> fences) {
        List<Fence> activeFences = fences.stream().filter(Fence::isActive).toList();
        if (livestockList.isEmpty()) return null; // no livestock = N/A
        if (activeFences.isEmpty()) return 1.0; // no fences = all "inside"

        long withGps = livestockList.stream()
                .filter(l -> l.getLastLatitude() != null && l.getLastLongitude() != null)
                .count();
        if (withGps == 0) return null; // no GPS data = N/A

        long inFence = livestockList.stream()
                .filter(l -> l.getLastLatitude() != null && l.getLastLongitude() != null)
                .filter(l -> {
                    GpsCoordinate pos = new GpsCoordinate(l.getLastLatitude(), l.getLastLongitude());
                    return activeFences.stream().anyMatch(f -> f.contains(pos));
                })
                .count();

        return (double) inFence / withGps;
    }

    /**
     * Build HealthOverview from data already loaded by getOverview(), avoiding the
     * duplicate snapshot/livestock/alert queries that getHealthOverview() would issue.
     * Semantics mirror HealthQueryPortAdapter.getHealthOverview().
     */
    private HealthOverview buildHealthOverview(
            List<Livestock> livestockList,
            List<LivestockHealthState> healthStates,
            List<Alert> activeAlerts) {
        Set<Long> activeLivestockIds = livestockList.stream()
                .map(Livestock::getId)
                .collect(Collectors.toSet());
        int total = activeLivestockIds.size();

        List<LivestockHealthState> active = healthStates.stream()
                .filter(h -> activeLivestockIds.contains(h.livestockId()))
                .toList();

        long healthyCount = active.stream()
                .filter(h -> "NORMAL".equals(h.tempStatus()) && "NORMAL".equals(h.motilityStatus()))
                .count();
        Double healthyRate = total > 0 ? (double) healthyCount / total : null;

        int criticalCount = (int) active.stream()
                .filter(h -> "CRITICAL".equals(h.tempStatus()))
                .count();
        int feverAbnormal = (int) active.stream()
                .filter(h -> "FEVER".equals(h.tempStatus()) || "CRITICAL".equals(h.tempStatus()))
                .count();
        int digestiveAbnormal = (int) active.stream()
                .filter(h -> "ABNORMAL".equals(h.motilityStatus()))
                .count();
        int digestiveWatch = (int) active.stream()
                .filter(h -> "LOW".equals(h.motilityStatus()))
                .count();
        int estrusHighScore = (int) active.stream()
                .filter(h -> h.estrusScore() >= 70)
                .count();
        double epidemicAbnormalRate = total > 0
                ? (double) active.stream()
                        .filter(h -> !"NORMAL".equals(h.tempStatus())
                                || !"NORMAL".equals(h.motilityStatus()))
                        .count() / total
                : 0.0;

        return new HealthOverview(
                total,
                healthyRate != null ? Math.round(healthyRate * 1000.0) / 1000.0 : null,
                activeAlerts.size(),
                criticalCount,
                feverAbnormal, criticalCount,
                digestiveAbnormal, digestiveWatch,
                estrusHighScore,
                Math.round(epidemicAbnormalRate * 1000.0) / 1000.0
        );
    }

    private Map<String, Integer> buildFenceAlertSummary(List<Alert> alerts) {
        Map<String, Integer> summary = new java.util.LinkedHashMap<>();
        summary.put("FENCE_BREACH", 0);
        summary.put("FENCE_APPROACH", 0);
        summary.put("ZONE_APPROACH", 0);
        for (Alert alert : alerts) {
            if (alert.getStatus() != AlertStatus.ACTIVE) continue;
            String type = alert.getType().name();
            if (summary.containsKey(type)) {
                summary.merge(type, 1, Integer::sum);
            }
        }
        return summary;
    }

    private Map<String, Integer> buildHealthAlertSummary(List<Alert> alerts) {
        Map<String, Integer> summary = new java.util.LinkedHashMap<>();
        summary.put("TEMPERATURE_ABNORMAL", 0);
        summary.put("DIGESTIVE_ABNORMAL", 0);
        summary.put("ESTRUS", 0);
        summary.put("EPIDEMIC", 0);
        for (Alert alert : alerts) {
            if (alert.getStatus() != AlertStatus.ACTIVE) continue;
            String type = alert.getType().name();
            if (summary.containsKey(type)) {
                summary.merge(type, 1, Integer::sum);
            }
        }
        return summary;
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
