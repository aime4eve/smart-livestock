package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.EpisodeBoard;
import com.smartlivestock.health.application.dto.HealthDtos.EpisodeRow;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Aggregates the per-scene workbench board (NIX-245): current snapshot state
 * + open health tickets + AI view for every livestock of the farm, grouped
 * into abnormal / recoveredToday / normal. All screens (workbench rows,
 * alert-center notifications, detail episode card) read the same numbers.
 *
 * Abnormal definitions are ticket-consistent (health alert bridge mapping):
 * fever = tempStatus in {ELEVATED, FEVER, CRITICAL}; digestive = motility
 * ABNORMAL (LOW is watch); estrus = score >= 70. Scene card "异常" and the
 * open-ticket count therefore reconcile by construction.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthEpisodeService {

    public static final String SCENE_FEVER = "fever";
    public static final String SCENE_DIGESTIVE = "digestive";
    public static final String SCENE_ESTRUS = "estrus";
    public static final String SCENE_EPIDEMIC = "epidemic";

    static final Set<String> FEVER_TYPES = Set.of("TEMPERATURE_ABNORMAL");
    static final Set<String> DIGESTIVE_TYPES = Set.of("DIGESTIVE_ABNORMAL");
    static final Set<String> ESTRUS_TYPES = Set.of("ESTRUS");
    static final Set<String> EPIDEMIC_TYPES = Set.of("EPIDEMIC");
    /** Health window used by the epidemic scene (7 days, spec §5.5). */
    static final Set<String> EPIDEMIC_SOURCE_TYPES = Set.of("TEMPERATURE_ABNORMAL", "DIGESTIVE_ABNORMAL", "EPIDEMIC");

    private final HealthSnapshotRepository snapshotRepo;
    private final RanchQueryPort ranchQueryPort;
    private final TemperatureLogRepository temperatureLogRepo;

    public EpisodeBoard board(Long farmId, String scene, Long userId) {
        Set<String> types = switch (scene) {
            case SCENE_FEVER -> FEVER_TYPES;
            case SCENE_DIGESTIVE -> DIGESTIVE_TYPES;
            case SCENE_ESTRUS -> ESTRUS_TYPES;
            case SCENE_EPIDEMIC -> EPIDEMIC_TYPES;
            default -> throw new IllegalArgumentException("unknown scene: " + scene);
        };

        List<LivestockInfo> livestock = ranchQueryPort.findAllByFarmId(farmId);
        Map<Long, HealthSnapshot> snapshots = snapshotRepo.findByFarmId(farmId).stream()
                .collect(Collectors.toMap(HealthSnapshot::getLivestockId, Function.identity(), (a, b) -> a));
        Map<Long, LivestockInfo> livestockById = livestock.stream()
                .collect(Collectors.toMap(LivestockInfo::id, Function.identity()));

        List<AlertBrief> active = ranchQueryPort.findActiveAlertsByFarmIdAndTypes(farmId,
                scene.equals(SCENE_EPIDEMIC) ? EPIDEMIC_SOURCE_TYPES : types);
        Map<Long, List<AlertBrief>> activeByLivestock = active.stream()
                .filter(a -> a.livestockId() != null)
                .collect(Collectors.groupingBy(AlertBrief::livestockId));
        Set<Long> readIds = userId == null ? Set.of()
                : ranchQueryPort.findReadAlertIds(userId,
                        active.stream().map(AlertBrief::alertId).toList());

        // Epidemic scene: abnormal set = livestock with a source-type alert in the 7d window
        Map<Long, AlertBrief> epidemicSet = new HashMap<>();
        if (scene.equals(SCENE_EPIDEMIC)) {
            Instant since = Instant.now().minus(Duration.ofDays(7));
            List<AlertBrief> recent = new ArrayList<>(active);
            recent.addAll(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(farmId, EPIDEMIC_SOURCE_TYPES, since));
            for (AlertBrief a : recent) {
                if (a.livestockId() != null) {
                    epidemicSet.merge(a.livestockId(), a,
                            (x, y) -> x.createdAt() != null && y.createdAt() != null && x.createdAt().isAfter(y.createdAt()) ? x : y);
                }
            }
        }

        // Recovered today: ticket resolved today AND current state no longer abnormal for the scene
        List<AlertBrief> resolvedToday = ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(
                farmId, types, LocalDate.now(ZoneOffset.UTC).atStartOfDay().toInstant(ZoneOffset.UTC));
        Set<Long> recoveredIds = resolvedToday.stream()
                .map(AlertBrief::livestockId)
                .filter(id -> id != null && livestockById.containsKey(id))
                .filter(id -> {
                    HealthSnapshot s = snapshots.get(id);
                    return s == null || !isAbnormal(scene, s);
                })
                .collect(Collectors.toSet());

        List<EpisodeRow> abnormal = new ArrayList<>();
        List<EpisodeRow> recovered = new ArrayList<>();
        List<EpisodeRow> normal = new ArrayList<>();

        for (LivestockInfo l : livestock) {
            HealthSnapshot snap = snapshots.get(l.id());
            boolean isAbnormal = scene.equals(SCENE_EPIDEMIC)
                    ? epidemicSet.containsKey(l.id())
                    : snap != null && isAbnormal(scene, snap);
            EpisodeRow row = buildRow(scene, l, snap,
                    activeByLivestock.getOrDefault(l.id(), List.of()),
                    readIds, snap == null ? null : feverTrend(l.id()));
            if (isAbnormal) {
                abnormal.add(row);
            } else if (recoveredIds.contains(l.id())) {
                recovered.add(row);
            } else {
                normal.add(row);
            }
        }

        int activeAlertCount = (int) active.stream()
                .filter(a -> a.livestockId() != null || scene.equals(SCENE_EPIDEMIC))
                .count();
        double rate = scene.equals(SCENE_EPIDEMIC) && !livestock.isEmpty()
                ? (double) epidemicSet.size() / livestock.size() : 0;

        return new EpisodeBoard(scene, livestock.size(), abnormal.size(), activeAlertCount,
                abnormal.size() == activeAlertCount, rate, abnormal, recovered, normal);
    }

    private boolean isAbnormal(String scene, HealthSnapshot s) {
        return switch (scene) {
            case SCENE_FEVER -> s.getTempStatus() == TempStatus.ELEVATED
                    || s.getTempStatus() == TempStatus.FEVER
                    || s.getTempStatus() == TempStatus.CRITICAL;
            case SCENE_DIGESTIVE -> s.getMotilityStatus() == MotilityStatus.ABNORMAL;
            case SCENE_ESTRUS -> s.getEstrusScore() != null && s.getEstrusScore() >= 70;
            default -> false;
        };
    }

    private EpisodeRow buildRow(String scene, LivestockInfo l, HealthSnapshot snap,
                                List<AlertBrief> alerts, Set<Long> readIds, String trend) {
        Double value;
        Double baseline;
        String level;
        switch (scene) {
            case SCENE_FEVER -> {
                value = snap != null && snap.getCurrentTemp() != null ? snap.getCurrentTemp().doubleValue() : null;
                baseline = snap != null && snap.getBaselineTemp() != null ? snap.getBaselineTemp().doubleValue() : null;
                level = snap == null ? "normal"
                        : snap.getTempStatus() == TempStatus.CRITICAL ? "critical"
                        : snap.getTempStatus() == TempStatus.FEVER ? "critical"
                        : snap.getTempStatus() == TempStatus.ELEVATED ? "warning" : "normal";
            }
            case SCENE_DIGESTIVE -> {
                value = snap != null && snap.getCurrentMotility() != null ? snap.getCurrentMotility().doubleValue() : null;
                baseline = snap != null && snap.getMotilityBaseline() != null ? snap.getMotilityBaseline().doubleValue() : null;
                level = snap != null && snap.getMotilityStatus() == MotilityStatus.ABNORMAL ? "warning" : "normal";
            }
            case SCENE_ESTRUS -> {
                value = snap != null && snap.getEstrusScore() != null ? snap.getEstrusScore().doubleValue() : null;
                baseline = null;
                level = snap != null && snap.getEstrusScore() != null && snap.getEstrusScore() >= 70 ? "warning" : "normal";
            }
            default -> {
                value = null;
                baseline = null;
                level = "normal";
            }
        }

        Instant earliest = alerts.stream().map(AlertBrief::createdAt)
                .filter(t -> t != null).min(Instant::compareTo).orElse(null);
        Double duration = earliest == null ? null
                : (double) Duration.between(earliest, Instant.now()).toMinutes() / 60.0;

        String severity = alerts.stream()
                .map(AlertBrief::severity)
                .filter(s -> "CRITICAL".equals(s))
                .findFirst()
                .orElse(alerts.isEmpty() ? null : alerts.get(0).severity());

        boolean unread = alerts.stream().anyMatch(a -> !readIds.contains(a.alertId()));

        double aiScore = snap != null && snap.getAiAnomalyScore() != null
                ? snap.getAiAnomalyScore().doubleValue() : 0;

        return new EpisodeRow(
                l.id(), l.livestockCode(), level, value, baseline, duration, trend,
                Math.round(aiScore * 1000.0) / 1000.0,
                AiHealthBands.band(aiScore),
                snap != null ? AiHealthBands.findingCode(snap.getAiAnomalyType()) : "none",
                snap != null ? snap.getAiAssessedAt() : null,
                alerts.size(), severity, unread);
    }

    /** Fever trend from the last two hours of readings: up / down / flat. */
    private String feverTrend(Long livestockId) {
        try {
            List<com.smartlivestock.health.domain.model.TemperatureLog> logs = temperatureLogRepo
                    .findByLivestockIdAndTimeRange(livestockId,
                            Instant.now().minus(Duration.ofHours(2)), Instant.now());
            if (logs.size() < 2) return "flat";
            // repository may hand back an immutable list — copy before sorting
            List<com.smartlivestock.health.domain.model.TemperatureLog> sorted = new ArrayList<>(logs);
            sorted.sort(java.util.Comparator.comparing(com.smartlivestock.health.domain.model.TemperatureLog::getRecordedAt));
            int half = sorted.size() / 2;
            double firstAvg = avg(sorted.subList(0, half));
            double lastAvg = avg(sorted.subList(half, sorted.size()));
            double delta = lastAvg - firstAvg;
            if (delta > 0.15) return "up";
            if (delta < -0.15) return "down";
            return "flat";
        } catch (Exception e) {
            return "flat";
        }
    }

    private double avg(List<com.smartlivestock.health.domain.model.TemperatureLog> logs) {
        return logs.stream()
                .filter(x -> x.getTemperature() != null)
                .mapToDouble(x -> x.getTemperature().doubleValue())
                .average().orElse(0);
    }

    /** Livestock ids referenced by ACTIVE health tickets but missing from the farm list (stale snapshots etc.). */
    public Set<Long> orphanAlertLivestock(Long farmId) {
        Set<Long> known = ranchQueryPort.findAllByFarmId(farmId).stream()
                .map(LivestockInfo::id).collect(Collectors.toSet());
        Set<Long> ids = new HashSet<>();
        ranchQueryPort.findActiveAlertsByFarmIdAndTypes(farmId,
                        Set.of("TEMPERATURE_ABNORMAL", "DIGESTIVE_ABNORMAL", "ESTRUS", "EPIDEMIC", "AI_ANOMALY"))
                .forEach(a -> { if (a.livestockId() != null && !known.contains(a.livestockId())) ids.add(a.livestockId()); });
        return ids;
    }
}
