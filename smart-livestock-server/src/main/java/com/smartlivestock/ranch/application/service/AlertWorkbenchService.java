package com.smartlivestock.ranch.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.EpisodeBoard;
import com.smartlivestock.health.application.dto.HealthDtos.EpisodeRow;
import com.smartlivestock.health.application.service.HealthEpisodeService;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.AiView;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.Asset;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.AssetSummary;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.BucketSummary;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.Reason;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.WorkbenchItem;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.WorkbenchResponse;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.WorkbenchSummary;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Management-facing alert aggregation: the first level is the action the ranch
 * must take; each row is anchored to the affected livestock/herd/fence/device.
 */
@Service
@RequiredArgsConstructor
public class AlertWorkbenchService {

    private static final Set<String> FENCE_TYPES = Set.of(
            "FENCE_BREACH", "FENCE_APPROACH", "ZONE_APPROACH");
    private static final Set<String> HEALTH_TYPES = Set.of(
            "TEMPERATURE_ABNORMAL", "DIGESTIVE_ABNORMAL", "ESTRUS", "EPIDEMIC", "AI_ANOMALY");
    private static final Set<String> DEVICE_TYPES = Set.of(
            "DEVICE_TAMPER", "DEVICE_LOW_BATTERY", "DEVICE_OFFLINE");
    private static final List<String> BUCKETS =
            List.of("immediate", "field", "observe", "resolved");

    private final AlertRepository alertRepository;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final SpringDataAlertReadStatusRepository readStatusRepository;
    private final IoTQueryPort ioTQueryPort;
    private final AlertMessageLocalizer messageLocalizer;
    private final HealthEpisodeService healthEpisodeService;

    @Transactional(readOnly = true)
    public WorkbenchResponse workbench(Long farmId, Long userId, String bucket,
                                       List<String> assets, Long fenceId, int page, int pageSize) {
        List<Alert> alerts = alertRepository.findByFarmId(farmId);
        Set<Long> readIds = userId == null || alerts.isEmpty()
                ? Set.of()
                : readStatusRepository.findReadAlertIdsByUserId(userId,
                        alerts.stream().map(Alert::getId).toList());

        Map<Long, Livestock> livestockMap = livestockRepository.findByFarmId(farmId).stream()
                .collect(Collectors.toMap(Livestock::getId, value -> value, (left, right) -> left));
        Map<Long, Fence> fenceMap = fenceRepository.findByFarmId(farmId).stream()
                .collect(Collectors.toMap(Fence::getId, value -> value, (left, right) -> left));
        Map<Long, String> deviceCodes = ioTQueryPort.findDeviceCodesByIds(
                alerts.stream().map(Alert::getDeviceId).filter(Objects::nonNull).distinct().toList());
        Map<Long, EpisodeRow> aiByLivestock = aiRows(farmId);

        List<WorkbenchItem> items = new ArrayList<>();
        items.addAll(alertItems(alerts, readIds, livestockMap, fenceMap, deviceCodes,
                aiByLivestock, false, fenceId));
        items.addAll(observeItems(aiByLivestock, alerts, livestockMap));
        items.addAll(alertItems(alerts, readIds, livestockMap, fenceMap, deviceCodes,
                aiByLivestock, true, fenceId));

        String requestedBucket = normalize(bucket);
        Set<String> requestedAssets = assets == null || assets.isEmpty()
                ? Set.of("all")
                : assets.stream().map(this::normalize).collect(Collectors.toSet());
        List<WorkbenchItem> filtered = items.stream()
                .filter(item -> "all".equals(requestedBucket) || requestedBucket.equals(item.bucket()))
                .filter(item -> requestedAssets.contains("all") || requestedAssets.contains(item.asset().kind()))
                .sorted(Comparator
                        .comparing((WorkbenchItem item) -> severityRank(item.severity())).reversed()
                        .thenComparing(item -> item.unread() ? 0 : 1)
                        .thenComparing(item -> item.occurredAt() == null ? Instant.EPOCH : item.occurredAt()))
                .toList();

        WorkbenchSummary summary = buildSummary(items);
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(pageSize, 1), 200);
        int from = Math.min((safePage - 1) * safeSize, filtered.size());
        int to = Math.min(from + safeSize, filtered.size());
        return new WorkbenchResponse(
                summary, filtered.subList(from, to), safePage, safeSize, filtered.size());
    }

    private List<WorkbenchItem> alertItems(List<Alert> alerts, Set<Long> readIds,
                                           Map<Long, Livestock> livestockMap,
                                           Map<Long, Fence> fenceMap,
                                           Map<Long, String> deviceCodes,
                                           Map<Long, EpisodeRow> aiByLivestock,
                                           boolean resolvedOnly, Long fenceId) {
        Instant resolvedSince = LocalDate.now(ZoneId.systemDefault())
                .atStartOfDay(ZoneId.systemDefault()).toInstant();
        Map<String, List<Alert>> grouped = alerts.stream()
                .filter(alert -> fenceId == null || fenceId.equals(alert.getFenceId()))
                .filter(alert -> resolvedOnly
                        ? alert.getStatus() != AlertStatus.ACTIVE
                                && alert.getResolvedAt() != null
                                && !alert.getResolvedAt().isBefore(resolvedSince)
                        : alert.getStatus() == AlertStatus.ACTIVE)
                .collect(Collectors.groupingBy(this::groupKey, LinkedHashMap::new, Collectors.toList()));

        return grouped.entrySet().stream()
                .map(entry -> toItem(entry.getKey(), entry.getValue(), readIds, livestockMap,
                        fenceMap, deviceCodes, aiByLivestock, resolvedOnly))
                .toList();
    }

    private WorkbenchItem toItem(String key, List<Alert> alerts, Set<Long> readIds,
                                 Map<Long, Livestock> livestockMap, Map<Long, Fence> fenceMap,
                                 Map<Long, String> deviceCodes, Map<Long, EpisodeRow> aiByLivestock,
                                 boolean resolvedOnly) {
        String assetKind = assetKind(key);
        Long assetId = assetId(key);
        Alert first = alerts.stream()
                .min(Comparator.comparing(alert -> alert.getCreatedAt() == null ? Instant.EPOCH : alert.getCreatedAt()))
                .orElseThrow();
        String severity = alerts.stream()
                .map(alert -> alert.getSeverity() == null ? "WARNING" : alert.getSeverity().name())
                .min(Comparator.comparing(this::severityRank).reversed())
                .orElse("WARNING");
        boolean unread = alerts.stream().anyMatch(alert -> !readIds.contains(alert.getId()));
        String bucket = resolvedOnly ? "resolved" : bucketOf(alerts, severity, aiByLivestock);
        String title = first.getMessageKey() == null ? first.getMessage() : messageLocalizer.localize(first);

        Livestock livestock = assetKind.equals("livestock") ? livestockMap.get(assetId) : null;
        Fence fence = assetKind.equals("fence") ? fenceMap.get(assetId) : null;
        String assetName = switch (assetKind) {
            case "livestock" -> livestock != null ? livestock.getLivestockCode() : "SL-" + assetId;
            case "fence" -> fence != null ? fence.getName() : "F-" + assetId;
            case "device" -> deviceCodes.getOrDefault(assetId, "D-" + assetId);
            default -> "HERD";
        };
        String assetSubtitle = switch (assetKind) {
            case "livestock" -> livestock != null && livestock.getBreed() != null ? livestock.getBreed() : "";
            case "fence" -> fence != null ? (fence.isActive() ? "active" : "inactive") : "";
            case "device" -> alerts.size() + " evidence";
            default -> "farm-wide";
        };
        Long aiLivestockId = assetKind.equals("livestock")
                ? assetId
                : alerts.stream().map(Alert::getLivestockId).filter(Objects::nonNull).findFirst().orElse(null);
        EpisodeRow episode = aiLivestockId == null ? null : aiByLivestock.get(aiLivestockId);

        List<Reason> reasons = alerts.stream()
                .sorted(Comparator.comparing(Alert::getCreatedAt,
                        Comparator.nullsFirst(Comparator.naturalOrder())))
                .map(alert -> new Reason(
                        alert.getId(),
                        alert.getType().name(),
                        alert.getSeverity() == null ? "WARNING" : alert.getSeverity().name(),
                        messageLocalizer.localize(alert),
                        alert.getCreatedAt(),
                        readIds.contains(alert.getId())))
                .toList();
        List<String> actions = actions(assetKind, episode, !resolvedOnly);
        String route = switch (assetKind) {
            case "livestock" -> "/livestock/" + assetId + "?section=health";
            case "fence" -> "/ranch?tab=fence&fenceId=" + assetId;
            case "device" -> "/devices?deviceId=" + assetId;
            default -> "/twin/epidemic";
        };
        Instant resolvedAt = alerts.stream().map(Alert::getResolvedAt)
                .filter(Objects::nonNull).max(Comparator.naturalOrder()).orElse(null);
        String resolvedType = alerts.stream().map(Alert::getResolvedType)
                .filter(Objects::nonNull).findFirst().orElse(null);

        return new WorkbenchItem(
                key,
                bucket,
                new Asset(assetKind, assetId == null ? "herd" : assetId.toString(), assetName, assetSubtitle),
                title,
                assetSubtitle,
                severity,
                unread,
                first.getCreatedAt(),
                resolvedAt,
                resolvedType,
                reasons,
                episode == null ? null : new AiView(episode.aiBand(), episode.aiFindingCode(),
                        episode.aiScore(), episode.aiAssessedAt()),
                actions,
                route
        );
    }

    private List<WorkbenchItem> observeItems(Map<Long, EpisodeRow> aiByLivestock,
                                             List<Alert> alerts,
                                             Map<Long, Livestock> livestockMap) {
        Set<Long> livestockWithHealthTickets = alerts.stream()
                .filter(alert -> alert.getStatus() == AlertStatus.ACTIVE
                        && HEALTH_TYPES.contains(alert.getType().name())
                        && alert.getLivestockId() != null)
                .map(Alert::getLivestockId)
                .collect(Collectors.toSet());
        return aiByLivestock.values().stream()
                .filter(row -> "watch".equals(row.aiBand()))
                .filter(row -> !livestockWithHealthTickets.contains(row.livestockId()))
                .map(row -> {
                    Livestock livestock = livestockMap.get(row.livestockId());
                    return new WorkbenchItem(
                            "observe-livestock-" + row.livestockId(),
                            "observe",
                            new Asset("livestock", row.livestockId().toString(),
                                    livestock != null ? livestock.getLivestockCode() : "SL-" + row.livestockId(),
                                    livestock != null && livestock.getBreed() != null ? livestock.getBreed() : ""),
                            livestock != null ? livestock.getLivestockCode() : "SL-" + row.livestockId(),
                            "AI watch observation",
                            "INFO",
                            false,
                            row.aiAssessedAt(),
                            null,
                            null,
                            List.of(),
                            new AiView(row.aiBand(), row.aiFindingCode(), row.aiScore(), row.aiAssessedAt()),
                            List.of("VIEW_LIVESTOCK", "VIEW_AI", "MARK_READ"),
                            "/livestock/" + row.livestockId() + "?section=health"
                    );
                })
                .toList();
    }

    private Map<Long, EpisodeRow> aiRows(Long farmId) {
        Map<Long, EpisodeRow> rows = new HashMap<>();
        for (String scene : List.of("fever", "digestive", "estrus", "epidemic")) {
            EpisodeBoard board = healthEpisodeService.board(farmId, scene, null);
            for (List<EpisodeRow> group : List.of(board.abnormal(), board.normal(), board.recoveredToday())) {
                for (EpisodeRow row : group) {
                    rows.merge(row.livestockId(), row, this::strongerEpisode);
                }
            }
        }
        return rows;
    }

    private EpisodeRow strongerEpisode(EpisodeRow left, EpisodeRow right) {
        return episodeRank(left) >= episodeRank(right) ? left : right;
    }

    private WorkbenchSummary buildSummary(List<WorkbenchItem> items) {
        List<BucketSummary> buckets = BUCKETS.stream().filter(key -> !"all".equals(key))
                .map(key -> new BucketSummary(
                        key,
                        items.stream().filter(item -> key.equals(item.bucket())).count(),
                        key.equals("resolved")
                                ? 0
                                : items.stream()
                                        .filter(item -> key.equals(item.bucket()) && item.unread())
                                        .count()))
                .toList();
        List<AssetSummary> assets = List.of("livestock", "herd", "fence", "device").stream()
                .map(kind -> new AssetSummary(
                        kind,
                        items.stream().filter(item -> !item.bucket().equals("resolved") && kind.equals(item.asset().kind())).count(),
                        items.stream().filter(item -> !item.bucket().equals("resolved")
                                && kind.equals(item.asset().kind()) && item.unread()).count()))
                .toList();
        return new WorkbenchSummary(buckets, assets);
    }

    private String groupKey(Alert alert) {
        String kind = assetKind(alert);
        Long id = switch (kind) {
            case "livestock" -> alert.getLivestockId();
            case "fence" -> alert.getFenceId();
            case "device" -> alert.getDeviceId();
            default -> null;
        };
        String status = alert.getStatus() == AlertStatus.ACTIVE ? "active" : "resolved";
        return kind + ":" + (id == null ? "farm" : id) + ":" + status;
    }

    private String assetKind(Alert alert) {
        String type = alert.getType().name();
        if (FENCE_TYPES.contains(type)) return "fence";
        if (DEVICE_TYPES.contains(type)) return "device";
        if (type.equals("EPIDEMIC")) return "herd";
        if (alert.getLivestockId() != null) return "livestock";
        return "herd";
    }

    private String assetKind(String groupKey) {
        return groupKey.split(":", 2)[0];
    }

    private Long assetId(String groupKey) {
        String value = groupKey.split(":")[1];
        return "farm".equals(value) ? null : Long.valueOf(value);
    }

    private String bucketOf(List<Alert> alerts, String severity, Map<Long, EpisodeRow> aiByLivestock) {
        boolean immediate = severity.equals("CRITICAL")
                || alerts.stream().map(alert -> alert.getType().name())
                        .anyMatch(type -> type.equals("FENCE_BREACH") || type.equals("EPIDEMIC")
                                || type.equals("DEVICE_TAMPER"));
        if (immediate) return "immediate";
        boolean field = alerts.stream().map(alert -> alert.getType().name())
                .anyMatch(type -> FENCE_TYPES.contains(type) || DEVICE_TYPES.contains(type));
        if (field) return "field";
        boolean watch = alerts.stream().map(Alert::getLivestockId).filter(Objects::nonNull)
                .anyMatch(livestockId -> aiByLivestock.get(livestockId) != null
                        && "watch".equals(aiByLivestock.get(livestockId).aiBand()));
        return watch ? "observe" : "field";
    }

    private List<String> actions(String assetKind, EpisodeRow episode, boolean active) {
        List<String> actions = new ArrayList<>();
        if (assetKind.equals("livestock")) {
            actions.add("LOCATE");
            actions.add("TRAJECTORY");
            actions.add("VIEW_LIVESTOCK");
        } else if (assetKind.equals("fence")) {
            actions.add("VIEW_FENCE");
            actions.add("LOCATE");
        } else if (assetKind.equals("device")) {
            actions.add("VIEW_DEVICE");
        }
        if (episode != null) actions.add("VIEW_AI");
        if (active) {
            actions.add("MARK_READ");
            actions.add("DISMISS");
        }
        return actions;
    }

    private int severityRank(String severity) {
        return switch (severity) {
            case "CRITICAL" -> 3;
            case "WARNING" -> 2;
            case "INFO" -> 1;
            default -> 0;
        };
    }

    private int episodeRank(EpisodeRow row) {
        return switch (row.statusLevel()) {
            case "critical" -> 4;
            case "warning" -> 3;
            case "watch" -> 2;
            default -> "watch".equals(row.aiBand()) ? 1 : 0;
        };
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? "all" : value.toLowerCase(Locale.ROOT);
    }
}
