package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.AnomalyScoreJpaRepository;
import com.smartlivestock.ranch.application.signal.SignalDtos.AiSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.AlertSummarySignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.DeviceSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.FenceSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.HealthMetricSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.HealthSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.LivestockSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.LivestockSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalDtos.MapFenceSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.MapSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalDtos.PositionSignal;
import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.application.signal.SignalRevisionService.MapCursor;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.GpsCoordinate;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.LivestockLocationSnapshotJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockLocationSnapshotJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class SignalQueryService {

    private static final int MAX_LIVESTOCK_IDS = 200;
    private static final int MAX_MAP_LIVESTOCK = 1_000;

    private final SignalRevisionService revisionService;
    private final LivestockRepository livestockRepository;
    private final LivestockLocationSnapshotJpaRepository locationRepository;
    private final HealthSnapshotRepository healthSnapshotRepository;
    private final AnomalyScoreJpaRepository anomalyScoreRepository;
    private final SpringDataAlertRepository alertRepository;
    private final FenceRepository fenceRepository;
    private final IoTQueryPort ioTQueryPort;

    @Transactional(readOnly = true)
    public LivestockSignalResponse getLivestockSignals(
            Long farmId, List<Long> requestedLivestockIds, String cursor, Long userId) {
        try {
            List<Long> livestockIds = normalizeLivestockIds(requestedLivestockIds, MAX_LIVESTOCK_IDS);
            FarmSignalRevision revision = revisionService.ensureFarm(farmId);
            long cursorRevision = parseListCursor(cursor);
            revisionService.validateListCursor(revision, cursorRevision);

            boolean changed = cursorRevision < revision.statusRevision();
            List<LivestockSignal> items = changed
                    ? buildLivestockSignals(farmId, livestockIds, userId, revision.statusRevision())
                    : List.of();
            return new LivestockSignalResponse(
                    farmId, revision.statusRevision(), changed, items
            );
        } catch (IllegalArgumentException e) {
            throw new com.smartlivestock.shared.common.ApiException(
                    com.smartlivestock.shared.common.ErrorCode.VALIDATION_ERROR, e.getMessage());
        } catch (IllegalStateException e) {
            throw new com.smartlivestock.shared.common.ApiException(
                    com.smartlivestock.shared.common.ErrorCode.SIGNAL_CURSOR_TOO_OLD,
                    e.getMessage() + "; resyncRequired=true"
            );
        }
    }

    @Transactional(readOnly = true)
    public MapSignalResponse getMapSignals(
            Long farmId, String cursor, boolean includeGeometry, Long userId) {
        try {
            FarmSignalRevision revision = revisionService.ensureFarm(farmId);
            MapCursor cursorState = revisionService.validateMapCursor(revision, cursor);

            List<Livestock> livestock = activeLivestock(farmId, null);
            if (livestock.size() > MAX_MAP_LIVESTOCK) {
                throw new IllegalArgumentException("Map signal endpoint is limited to 1,000 active livestock");
            }

        List<Long> livestockIds = livestock.stream().map(Livestock::getId).toList();
            boolean statusChanged = revision.statusRevision() > cursorState.statusRevision();
            boolean positionChanged = revision.positionRevision() > cursorState.positionRevision();
            boolean fenceGeometryChanged =
                    revision.fenceGeometryRevision() > cursorState.fenceGeometryRevision();
            boolean changed = statusChanged || positionChanged || fenceGeometryChanged;

            List<LivestockSignal> signals = statusChanged
                    ? buildLivestockSignals(farmId, livestockIds, userId, revision.statusRevision())
                    : List.of();
            List<PositionSignal> positions = positionChanged
                    ? locationRepository
                            .findByFarmIdAndPositionRevisionGreaterThan(farmId, cursorState.positionRevision())
                            .stream()
                            .map(this::toPositionSignal)
                            .toList()
                    : List.of();

        List<Fence> fences = fenceRepository.findByFarmId(farmId);
        List<Alert> activeAlerts = alertRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .stream().map(this::toAlert).toList();
        List<LivestockLocationSnapshotJpaEntity> snapshots =
                locationRepository.findByFarmId(farmId);
            List<MapFenceSignal> fenceSignals = changed
                    ? buildFenceSignals(
                            fences,
                            activeAlerts,
                            snapshots,
                            fenceGeometryChanged || includeGeometry,
                            revision.fenceGeometryRevision()
                    )
                    : List.of();

            return new MapSignalResponse(
                farmId,
                revision.statusRevision(),
                revision.positionRevision(),
                revision.fenceGeometryRevision(),
                revision.statusRevision() + ":" + revision.positionRevision() + ":"
                        + revision.fenceGeometryRevision(),
                changed,
                statusChanged,
                positionChanged,
                fenceGeometryChanged,
                fenceSignals,
                signals,
                positions
            );
        } catch (IllegalArgumentException e) {
            throw new com.smartlivestock.shared.common.ApiException(
                    com.smartlivestock.shared.common.ErrorCode.VALIDATION_ERROR, e.getMessage());
        } catch (IllegalStateException e) {
            throw new com.smartlivestock.shared.common.ApiException(
                    com.smartlivestock.shared.common.ErrorCode.SIGNAL_CURSOR_TOO_OLD,
                    e.getMessage() + "; resyncRequired=true"
            );
        }
    }

    private List<LivestockSignal> buildLivestockSignals(
            Long farmId, List<Long> requestedIds, Long userId, long revision) {
        List<Livestock> livestock = activeLivestock(farmId, requestedIds);
        if (livestock.isEmpty()) return List.of();

        List<Long> livestockIds = livestock.stream().map(Livestock::getId).toList();
        List<Alert> activeAlerts = alertRepository.findByFarmIdAndStatus(farmId, "ACTIVE")
                .stream().map(this::toAlert).toList();
        Map<Long, List<Alert>> alertsByLivestock = activeAlerts.stream()
                .filter(alert -> alert.getLivestockId() != null)
                .collect(java.util.stream.Collectors.groupingBy(Alert::getLivestockId));
        Map<Long, Integer> unreadCounts = unreadCountMap(farmId, userId);
        Map<Long, HealthSnapshot> snapshots = healthSnapshotRepository.findByFarmId(farmId)
                .stream()
                .collect(java.util.stream.Collectors.toMap(
                        HealthSnapshot::getLivestockId, snapshot -> snapshot, (a, b) -> a));
        Map<Long, AnomalyScoreJpaRepository.LatestScoreProjection> aiScores =
                anomalyScoreRepository.findLatestByLivestockIds(farmId, livestockIds)
                        .stream()
                        .collect(java.util.stream.Collectors.toMap(
                                AnomalyScoreJpaRepository.LatestScoreProjection::getLivestockId,
                                score -> score,
                                (a, b) -> a));
        Map<Long, List<com.smartlivestock.ranch.domain.port.dto.DeviceBrief>> devices =
                ioTQueryPort.findActiveDevicesByLivestockIds(livestockIds);
        List<Fence> fences = fenceRepository.findByFarmId(farmId);
        Map<Long, LivestockLocationSnapshotJpaEntity> locations =
                locationRepository.findByFarmId(farmId).stream()
                        .collect(java.util.stream.Collectors.toMap(
                                LivestockLocationSnapshotJpaEntity::getLivestockId,
                                snapshot -> snapshot,
                                (a, b) -> a));

        return livestock.stream()
                .map(animal -> toSignal(
                        animal,
                        revision,
                        alertsByLivestock.getOrDefault(animal.getId(), List.of()),
                        unreadCounts.getOrDefault(animal.getId(), 0),
                        snapshots.get(animal.getId()),
                        aiScores.get(animal.getId()),
                        devices.getOrDefault(animal.getId(), List.of()),
                        fences,
                        locations.get(animal.getId())
                ))
                .toList();
    }

    private LivestockSignal toSignal(
            Livestock livestock,
            long revision,
            List<Alert> activeAlerts,
            int unreadCount,
            HealthSnapshot snapshot,
            AnomalyScoreJpaRepository.LatestScoreProjection aiScore,
            List<com.smartlivestock.ranch.domain.port.dto.DeviceBrief> devices,
            List<Fence> fences,
            LivestockLocationSnapshotJpaEntity location
    ) {
        List<String> activeTypes = activeAlerts.stream()
                .map(alert -> alert.getType().name())
                .distinct()
                .toList();
        boolean critical = activeAlerts.stream()
                .anyMatch(alert -> alert.getSeverity() == Severity.CRITICAL);
        boolean warning = activeAlerts.stream()
                .anyMatch(alert -> alert.getSeverity() == Severity.WARNING);

        HealthMetricSignal temp = metricSignal(
                snapshot == null ? null : snapshot.getCurrentTemp(),
                "CELSIUS",
                snapshot == null ? null : mapTemperatureStatus(snapshot.getTempStatus().name()),
                snapshot == null ? null : snapshot.getCurrentTempRecordedAt(),
                snapshot == null ? null : snapshot.getCurrentTempSource()
        );
        HealthMetricSignal motility = metricSignal(
                snapshot == null ? null : snapshot.getCurrentMotility(),
                "TIMES_PER_MINUTE",
                snapshot == null ? null : mapMotilityStatus(snapshot.getMotilityStatus().name()),
                snapshot == null ? null : snapshot.getCurrentMotilityRecordedAt(),
                snapshot == null ? null : snapshot.getCurrentMotilitySource()
        );

        String healthStatus = critical ? "CRITICAL" : warning ? "WATCH" :
                "CRITICAL".equals(temp.status()) || "CRITICAL".equals(motility.status())
                        ? "CRITICAL" : "WATCH".equals(temp.status()) || "WATCH".equals(motility.status())
                        ? "WATCH" : "NORMAL";

        boolean aiAlert = activeTypes.contains("AI_ANOMALY");
        AiSignal ai = aiScore == null ? new AiSignal("NONE", null, null, null)
                : new AiSignal(
                        aiAlert ? "ALERT" : aiScore.getAnomalyScore().doubleValue() >= 0.4 ? "OBSERVE" : "NONE",
                        aiScore.getAnomalyScore().doubleValue(),
                        aiScore.getAnomalyType(),
                        aiScore.getCreatedAt()
                );

        GpsCoordinate position = location == null ? null : new GpsCoordinate(
                location.getLatitude(),
                location.getLongitude()
        );
        boolean insideAnyFence = position != null && fences.stream()
                .filter(Fence::isActive)
                .anyMatch(fence -> fence.contains(position));
        String fenceStatus = activeTypes.contains("FENCE_BREACH") ? "BREACH"
                : activeTypes.contains("FENCE_APPROACH") || activeTypes.contains("ZONE_APPROACH")
                ? "APPROACH" : position != null && !fences.isEmpty() && !insideAnyFence
                ? "BREACH" : "NORMAL";

        List<String> deviceFaults = activeTypes.stream()
                .filter(type -> type.equals("DEVICE_OFFLINE")
                        || type.equals("DEVICE_LOW_BATTERY")
                        || type.equals("DEVICE_TAMPER"))
                .toList();
        DeviceSignal device = new DeviceSignal(
                deviceFaults.contains("DEVICE_OFFLINE") ? "OFFLINE"
                        : deviceFaults.isEmpty() ? "NORMAL" : "FAULT",
                deviceFaults,
                devices.size()
        );

        return new LivestockSignal(
                livestock.getId(),
                livestock.getLivestockCode(),
                revision,
                new HealthSignal(healthStatus, activeTypes, temp, motility),
                ai,
                new FenceSignal(fenceStatus, activeTypes.stream()
                        .filter(type -> type.equals("FENCE_BREACH")
                                || type.equals("FENCE_APPROACH")
                                || type.equals("ZONE_APPROACH"))
                        .toList()),
                device,
                new AlertSummarySignal(activeAlerts.size(), unreadCount)
        );
    }

    private List<MapFenceSignal> buildFenceSignals(
            List<Fence> fences,
            List<Alert> activeAlerts,
            List<LivestockLocationSnapshotJpaEntity> snapshots,
            boolean includeGeometry,
            long revision
    ) {
        return fences.stream()
                .map(fence -> {
                    List<String> types = activeAlerts.stream()
                            .filter(alert -> fence.getId().equals(alert.getFenceId()))
                            .map(alert -> alert.getType().name())
                            .distinct()
                            .toList();
                    int count = (int) snapshots.stream()
                            .filter(snapshot -> fence.contains(new GpsCoordinate(
                                    snapshot.getLatitude(),
                                    snapshot.getLongitude()
                            )))
                            .count();
                    return new MapFenceSignal(
                            fence.getId(),
                            fence.getName(),
                            revision,
                            types.contains("FENCE_BREACH") ? "BREACH"
                                    : types.contains("FENCE_APPROACH")
                                    || types.contains("ZONE_APPROACH") ? "APPROACH" : "NORMAL",
                            types,
                            count,
                            includeGeometry ? fence.getVertices().stream()
                                    .map(point -> List.of(point.latitude(), point.longitude()))
                                    .toList() : null
                    );
                })
                .toList();
    }

    private PositionSignal toPositionSignal(LivestockLocationSnapshotJpaEntity snapshot) {
        long age = Math.max(0, Duration.between(snapshot.getRecordedAt(), Instant.now()).getSeconds());
        return new PositionSignal(
                snapshot.getLivestockId(),
                snapshot.getPositionRevision(),
                snapshot.getLatitude(),
                snapshot.getLongitude(),
                snapshot.getRecordedAt(),
                age,
                locationFreshness(age),
                snapshot.getSource()
        );
    }

    private HealthMetricSignal metricSignal(
            BigDecimal rawValue, String unit, String status, Instant recordedAt, String source) {
        if (rawValue == null) {
            return new HealthMetricSignal(null, unit, "MISSING", null, null, "MISSING", null);
        }
        long age = recordedAt == null
                ? -1
                : Math.max(0, Duration.between(recordedAt, Instant.now()).getSeconds());
        String freshness = recordedAt == null ? "MISSING" : metricFreshness(age);
        return new HealthMetricSignal(
                rawValue.doubleValue(),
                unit,
                status == null ? "NORMAL" : status,
                recordedAt,
                age,
                freshness,
                normalizeMetricSource(source)
        );
    }

    private String mapTemperatureStatus(String raw) {
        return switch (raw) {
            case "ELEVATED", "FEVER" -> "WATCH";
            case "CRITICAL" -> "CRITICAL";
            default -> "NORMAL";
        };
    }

    private String mapMotilityStatus(String raw) {
        return switch (raw) {
            case "LOW" -> "WATCH";
            case "ABNORMAL" -> "CRITICAL";
            default -> "NORMAL";
        };
    }

    private String locationFreshness(long ageSeconds) {
        if (ageSeconds <= 120) return "FRESH";
        if (ageSeconds <= 600) return "DELAYED";
        return "STALE";
    }

    private String metricFreshness(long ageSeconds) {
        if (ageSeconds <= 1800) return "FRESH";
        if (ageSeconds <= 3600) return "DELAYED";
        return "STALE";
    }

    private String normalizeMetricSource(String source) {
        return source != null
                && Set.of("AGENTIC_PLATFORM", "THINGSBOARD", "DATAGEN", "HTTP", "MANUAL_IMPORT")
                .contains(source) ? source : null;
    }

    private Map<Long, Integer> unreadCountMap(Long farmId, Long userId) {
        if (userId == null) return Map.of();
        Map<Long, Integer> result = new HashMap<>();
        alertRepository.countActiveUnreadByLivestock(farmId, userId)
                .forEach(row -> result.put(row.getLivestockId(), (int) row.getCnt()));
        return result;
    }

    private List<Livestock> activeLivestock(Long farmId, List<Long> requestedIds) {
        List<Livestock> all = livestockRepository.findByFarmId(farmId);
        if (requestedIds == null || requestedIds.isEmpty()) return all;
        Set<Long> wanted = new HashSet<>(requestedIds);
        return all.stream().filter(item -> wanted.contains(item.getId())).toList();
    }

    private List<Long> normalizeLivestockIds(List<Long> requested, int limit) {
        if (requested == null || requested.isEmpty()) {
            throw new IllegalArgumentException("livestockIds is required");
        }
        List<Long> normalized = new ArrayList<>(new LinkedHashSet<>(requested));
        if (normalized.size() > limit) {
            throw new IllegalArgumentException("livestockIds is limited to " + limit);
        }
        return normalized;
    }

    private long parseListCursor(String cursor) {
        try {
            long value = Long.parseLong(cursor == null || cursor.isBlank() ? "0" : cursor);
            if (value < 0) throw new NumberFormatException();
            return value;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("cursor must be a non-negative integer", e);
        }
    }

    private Alert toAlert(com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity entity) {
        Alert alert = new Alert(
                entity.getFarmId(),
                entity.getLivestockId(),
                entity.getFenceId(),
                entity.getDeviceId(),
                com.smartlivestock.ranch.domain.model.AlertType.valueOf(entity.getType()),
                Severity.valueOf(entity.getSeverity()),
                entity.getMessage()
        );
        alert.setId(entity.getId());
        return alert;
    }
}
