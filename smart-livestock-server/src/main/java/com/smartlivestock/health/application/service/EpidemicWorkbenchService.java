package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.EpidemicAnimalRef;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicDispositionRequest;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicDispositionResponse;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicEventItem;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicGraphEdge;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicGraphNode;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicGraphPath;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicHealthSignal;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicHerdMetricsData;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicLivestockWorkbenchItem;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicNetworkGraph;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicSourceData;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicTierSummary;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicWorkbenchContext;
import com.smartlivestock.health.application.dto.HealthDtos.EpidemicWorkbenchResponse;
import com.smartlivestock.health.domain.model.ContactTrace;
import com.smartlivestock.health.domain.model.EpidemicDispositionAction;
import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.domain.model.EpidemicDispositionTier;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.ContactTraceRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.service.EpidemicAnalysisService;
import com.smartlivestock.health.domain.service.EpidemicDispositionRules;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.entity.EpidemicDispositionJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Authoritative aggregation for the three-view epidemic workbench. The client
 * renders but never recomputes risk scores or disposition importance.
 */
@Service
@RequiredArgsConstructor
public class EpidemicWorkbenchService {

    private static final Set<String> HEALTH_ALERT_TYPES = Set.of(
            "TEMPERATURE_ABNORMAL", "DIGESTIVE_ABNORMAL", "EPIDEMIC", "AI_ANOMALY");

    private final ContactTraceRepository contactTraceRepository;
    private final HealthSnapshotRepository healthSnapshotRepository;
    private final RanchQueryPort ranchQueryPort;
    private final EpidemicAnalysisService epidemicAnalysisService;
    private final EpidemicDispositionJpaRepository dispositionRepository;

    @Value("${health.epidemic.workbench.critical-risk:70}")
    private int criticalRisk;

    @Value("${health.epidemic.workbench.critical-no-health-risk:80}")
    private int criticalNoHealthRisk;

    @Value("${health.epidemic.workbench.observation-risk:40}")
    private int observationRisk;

    @Transactional(readOnly = true)
    public EpidemicWorkbenchResponse workbench(Long farmId, Long sourceLivestockId,
                                               int windowHours, int maxDepth, String tierCsv) {
        Instant now = Instant.now();
        List<ContactTrace> allTraces = contactTraceRepository.findByFarmIdOrderByLastContactAtDesc(farmId);
        Long resolvedSourceId = sourceLivestockId != null
                ? sourceLivestockId : latestMarkedSource(allTraces, sourceLivestockId);
        if (resolvedSourceId == null) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.epidemicSourceNotFound");
        }

        Optional<ContactTrace> markedTrace = allTraces.stream()
                .filter(trace -> resolvedSourceId.equals(trace.getFromLivestockId()))
                .filter(trace -> trace.getMarkedAt() != null)
                .findFirst();
        var sourceInfo = ranchQueryPort.findLivestockById(resolvedSourceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.epidemicSourceNotFound"));
        int safeWindow = windowHours == 0 ? 0 : Math.min(Math.max(windowHours, 1), 24 * 30);
        Instant cutoff = safeWindow == 0 ? Instant.EPOCH : now.minus(Duration.ofHours(safeWindow));
        List<ContactTrace> windowTraces = allTraces.stream()
                .filter(trace -> trace.getLastContactAt() != null && trace.getLastContactAt().isAfter(cutoff))
                .toList();

        List<EpidemicEventItem> events = windowTraces.stream()
                .map(trace -> toEvent(trace, now))
                .sorted(Comparator.comparingInt(EpidemicEventItem::riskScore).reversed()
                        .thenComparing(EpidemicEventItem::lastContactAt))
                .toList();
        Map<Long, EpidemicEventItem> eventById = events.stream()
                .collect(Collectors.toMap(item -> Long.valueOf(item.eventId()), Function.identity(), (l, r) -> l));

        GraphResult graph = buildGraph(resolvedSourceId, windowTraces, eventById, Math.min(Math.max(maxDepth, 1), 3));
        Map<Long, HealthSnapshot> snapshots = healthSnapshotRepository.findByFarmId(farmId).stream()
                .collect(Collectors.toMap(HealthSnapshot::getLivestockId, Function.identity(), (l, r) -> l));
        Set<Long> healthAlertLivestock = ranchQueryPort
                .findActiveAlertsByFarmIdAndTypes(farmId, HEALTH_ALERT_TYPES).stream()
                .map(RanchQueryPort.AlertBrief::livestockId)
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());
        Map<Long, EpidemicDispositionJpaEntity> activeTasks = activeTasksByLivestock(farmId);
        Map<String, List<Long>> eventIdsByAnimal = eventIdsByAnimal(events, resolvedSourceId);

        List<EpidemicLivestockWorkbenchItem> livestock = graph.depths.keySet().stream()
                .filter(id -> !id.equals(resolvedSourceId))
                .map(id -> buildLivestockItem(id, resolvedSourceId, graph, events, snapshots,
                        healthAlertLivestock, activeTasks, eventIdsByAnimal, now))
                .filter(java.util.Objects::nonNull)
                .sorted(Comparator
                        .comparingInt((EpidemicLivestockWorkbenchItem item) ->
                                EpidemicDispositionTier.valueOf(item.dispositionTier()).getRank())
                        .thenComparingInt(EpidemicLivestockWorkbenchItem::maxRiskScore).reversed()
                        .thenComparing(item -> item.lastContactAt() == null ? Instant.EPOCH : item.lastContactAt())
                        .thenComparing(EpidemicLivestockWorkbenchItem::livestockCode))
                .toList();

        Set<String> requestedTiers = parseTiers(tierCsv);
        List<EpidemicLivestockWorkbenchItem> filteredLivestock = livestock.stream()
                .filter(item -> requestedTiers.isEmpty() || requestedTiers.contains(item.dispositionTier()))
                .toList();
        Map<Long, EpidemicLivestockWorkbenchItem> livestockById = livestock.stream()
                .collect(Collectors.toMap(item -> Long.valueOf(item.livestockId()), Function.identity(), (l, r) -> l));

        return new EpidemicWorkbenchResponse(
                context(farmId, sourceInfo, resolvedSourceId, markedTrace, safeWindow, now),
                tierSummaries(livestock),
                filteredLivestock,
                events,
                graph.graph(sourceInfo.livestockCode(), this::code, livestockById)
        );
    }

    @Transactional
    public EpidemicDispositionResponse createDisposition(Long farmId, EpidemicDispositionRequest request,
                                                         boolean manager) {
        if (request == null || request.livestockId() == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "validation.epidemicLivestockRequired");
        }
        Optional<EpidemicDispositionJpaEntity> active = dispositionRepository
                .findFirstByFarmIdAndLivestockIdAndStatusInOrderByUpdatedAtDesc(
                        farmId, request.livestockId(),
                        List.of(EpidemicDispositionStatus.PENDING, EpidemicDispositionStatus.IN_PROGRESS));
        if (active.isPresent()) {
            return toResponse(active.get());
        }

        var workbench = workbench(farmId, request.sourceLivestockId(), 72, 2, null);
        EpidemicLivestockWorkbenchItem item = workbench.livestock().stream()
                .filter(value -> request.livestockId().toString().equals(value.livestockId()))
                .findFirst()
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.epidemicLivestockNotFound"));
        EpidemicDispositionTier tier = EpidemicDispositionTier.valueOf(item.dispositionTier());
        EpidemicDispositionAction action = parseAction(request.actionCode(), item.recommendedAction());
        if (tier == EpidemicDispositionTier.CRITICAL && !manager) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.epidemicCriticalManagerRequired");
        }

        EpidemicDispositionJpaEntity entity = new EpidemicDispositionJpaEntity();
        entity.setFarmId(farmId);
        entity.setLivestockId(request.livestockId());
        entity.setSourceLivestockId(request.sourceLivestockId());
        entity.setSourceEventId(request.eventId());
        entity.setTier(tier);
        entity.setActionCode(action);
        entity.setStatus(EpidemicDispositionStatus.PENDING);
        entity.setReasonCodes(new ArrayList<>(item.reasonCodes()));
        entity.setDueAt(item.dueAt());
        return toResponse(dispositionRepository.save(entity));
    }

    @Transactional
    public EpidemicDispositionResponse completeDisposition(Long farmId, Long dispositionId,
                                                           Long userId, boolean manager) {
        EpidemicDispositionJpaEntity entity = dispositionRepository.findById(dispositionId)
                .filter(value -> value.getFarmId().equals(farmId))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.epidemicDispositionNotFound"));
        if (entity.getTier() == EpidemicDispositionTier.CRITICAL && !manager) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.epidemicCriticalManagerRequired");
        }
        entity.setStatus(EpidemicDispositionStatus.COMPLETED);
        entity.setCompletedAt(Instant.now());
        entity.setCompletedBy(userId);
        return toResponse(dispositionRepository.save(entity));
    }

    @Transactional
    public EpidemicDispositionResponse cancelDisposition(Long farmId, Long dispositionId, String reasonCode) {
        EpidemicDispositionJpaEntity entity = dispositionRepository.findById(dispositionId)
                .filter(value -> value.getFarmId().equals(farmId))
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.epidemicDispositionNotFound"));
        entity.setStatus(EpidemicDispositionStatus.CANCELLED);
        entity.setCancelReasonCode(reasonCode == null || reasonCode.isBlank() ? "USER_CANCELLED" : reasonCode);
        return toResponse(dispositionRepository.save(entity));
    }

    @Transactional
    public void cancelActiveBySource(Long sourceLivestockId) {
        dispositionRepository.findBySourceLivestockIdAndStatusIn(
                        sourceLivestockId,
                        List.of(EpidemicDispositionStatus.PENDING, EpidemicDispositionStatus.IN_PROGRESS))
                .forEach(entity -> {
                    entity.setStatus(EpidemicDispositionStatus.CANCELLED);
                    entity.setCancelReasonCode("SOURCE_UNMARKED");
                    dispositionRepository.save(entity);
                });
    }

    private Long latestMarkedSource(List<ContactTrace> traces, Long requested) {
        return traces.stream()
                .filter(trace -> requested == null || requested.equals(trace.getFromLivestockId()))
                .filter(trace -> trace.getMarkedAt() != null)
                .max(Comparator.comparing(ContactTrace::getMarkedAt,
                        Comparator.nullsFirst(Comparator.naturalOrder())))
                .map(ContactTrace::getFromLivestockId)
                .orElse(requested);
    }

    private EpidemicWorkbenchContext context(Long farmId, LivestockInfo source,
                                             Long sourceId, Optional<ContactTrace> markedTrace,
                                             int window, Instant now) {
        var snapshots = healthSnapshotRepository.findByFarmId(farmId);
        var metrics = epidemicAnalysisService.calculateHerdMetrics(snapshots);
        Integer lastAge = contactTraceRepository.findByFarmIdOrderByLastContactAtDesc(farmId).stream()
                .filter(trace -> sourceId.equals(trace.getFromLivestockId())
                        || sourceId.equals(trace.getToLivestockId()))
                .map(ContactTrace::getLastContactAt)
                .filter(java.util.Objects::nonNull)
                .max(Comparator.naturalOrder())
                .map(value -> (int) Duration.between(value, now).toMinutes())
                .orElse(null);
        return new EpidemicWorkbenchContext(
                new EpidemicSourceData(source.id().toString(), source.livestockCode(),
                        markedTrace.map(ContactTrace::getDiseaseType).orElse(null),
                        markedTrace.map(ContactTrace::getMarkedAt).orElse(null),
                        markedTrace.isPresent() ? "SUSPECTED" : "UNMARKED"),
                window,
                now,
                now,
                new EpidemicHerdMetricsData(metrics.avgTemperature(),
                        metrics.abnormalRate().doubleValue(), metrics.totalLivestock(),
                        metrics.abnormalCount(), epidemicAnalysisService.assessRiskLevel(metrics.abnormalRate())),
                lastAge
        );
    }

    private EpidemicEventItem toEvent(ContactTrace trace, Instant now) {
        int timeScore = timeScore(trace.getLastContactAt(), now);
        int distanceScore = distanceScore(trace.getProximityMeters());
        int durationScore = durationScore(trace.getContactDurationMinutes());
        int score = timeScore + distanceScore + durationScore;
        long hours = trace.getLastContactAt() == null
                ? Long.MAX_VALUE : Duration.between(trace.getLastContactAt(), now).toHours();
        return new EpidemicEventItem(
                trace.getId(),
                new EpidemicAnimalRef(trace.getFromLivestockId().toString(), code(trace.getFromLivestockId())),
                new EpidemicAnimalRef(trace.getToLivestockId().toString(), code(trace.getToLivestockId())),
                trace.getProximityMeters() == null ? 0 : trace.getProximityMeters().doubleValue(),
                trace.getContactDurationMinutes() == null ? 0 : trace.getContactDurationMinutes(),
                trace.getLastContactAt(), hours, timeScore, distanceScore, durationScore,
                score, riskLevel(score), factors(trace, now)
        );
    }

    private GraphResult buildGraph(Long sourceId, List<ContactTrace> traces,
                                   Map<Long, EpidemicEventItem> eventById, int maxDepth) {
        Map<Long, List<ContactTrace>> adjacency = new HashMap<>();
        for (ContactTrace trace : traces) {
            adjacency.computeIfAbsent(trace.getFromLivestockId(), ignored -> new ArrayList<>()).add(trace);
            adjacency.computeIfAbsent(trace.getToLivestockId(), ignored -> new ArrayList<>()).add(trace);
        }

        Map<Long, Integer> depths = new HashMap<>();
        Map<Long, PathData> paths = new HashMap<>();
        depths.put(sourceId, 0);
        paths.put(sourceId, new PathData(new ArrayList<>(List.of(sourceId)), new ArrayList<>(), 0));
        record QueueItem(Long id, PathData path) {}
        List<QueueItem> queue = new ArrayList<>(List.of(new QueueItem(sourceId, paths.get(sourceId))));
        Set<String> edgeIds = new LinkedHashSet<>();

        for (int index = 0; index < queue.size(); index++) {
            QueueItem current = queue.get(index);
            if (current.path().nodes().size() - 1 >= maxDepth) continue;
            for (ContactTrace trace : adjacency.getOrDefault(current.id(), List.of())) {
                Long next = trace.getFromLivestockId().equals(current.id())
                        ? trace.getToLivestockId() : trace.getFromLivestockId();
                if (current.path().nodes().contains(next)) continue;
                int nextDepth = current.path().nodes().size();
                EpidemicEventItem event = eventById.get(trace.getId());
                int risk = event == null ? 0 : event.riskScore();
                if (depths.containsKey(next) && depths.get(next) <= nextDepth) continue;
                PathData nextPath = current.path().append(next, trace.getId(), risk);
                depths.put(next, nextDepth);
                paths.put(next, nextPath);
                edgeIds.add(String.valueOf(trace.getId()));
                queue.add(new QueueItem(next, nextPath));
            }
        }
        return new GraphResult(sourceId, depths, paths, eventById, maxDepth);
    }

    private EpidemicLivestockWorkbenchItem buildLivestockItem(Long livestockId, Long sourceId,
                                                              GraphResult graph,
                                                              List<EpidemicEventItem> events,
                                                              Map<Long, HealthSnapshot> snapshots,
                                                              Set<Long> healthAlertLivestock,
                                                              Map<Long, EpidemicDispositionJpaEntity> activeTasks,
                                                              Map<String, List<Long>> eventIdsByAnimal,
                                                              Instant now) {
        List<EpidemicEventItem> related = events.stream()
                .filter(event -> livestockId.toString().equals(event.from().livestockId())
                        || livestockId.toString().equals(event.to().livestockId()))
                .toList();
        EpidemicEventItem direct = related.stream()
                .filter(event -> isDirectSource(event, sourceId))
                .min(Comparator.comparing(EpidemicEventItem::lastContactAt,
                        Comparator.nullsFirst(Comparator.naturalOrder())))
                .orElse(null);
        if (related.isEmpty() || !graph.paths.containsKey(livestockId)) return null;

        int maxRisk = related.stream().mapToInt(EpidemicEventItem::riskScore).max().orElse(0);
        Instant lastContact = related.stream().map(EpidemicEventItem::lastContactAt)
                .filter(java.util.Objects::nonNull).max(Comparator.naturalOrder()).orElse(null);
        HealthSnapshot snapshot = snapshots.get(livestockId);
        boolean health = hasHealthSignal(snapshot, healthAlertLivestock.contains(livestockId));
        int depth = graph.depths.getOrDefault(livestockId, Integer.MAX_VALUE);
        int directAgeHours = direct == null || direct.lastContactAt() == null
                ? Integer.MAX_VALUE : (int) Duration.between(direct.lastContactAt(), now).toHours();
        List<String> reasons = new ArrayList<>();
        if (direct != null) reasons.add("DIRECT_SOURCE");
        if (direct != null) reasons.addAll(direct.factorCodes());
        if (health) reasons.add("HEALTH_ABNORMAL");
        if (!directSourceClassification(direct, directAgeHours, maxRisk, health)
                && depth <= 2 && maxRisk >= criticalRisk) reasons.add("PATH_EXPOSURE");

        var rule = EpidemicDispositionRules.classify(
                direct != null, directAgeHours, maxRisk, depth, health,
                criticalRisk, criticalNoHealthRisk, observationRisk);
        var dueAt = rule.dueHours() == null
                ? null : now.plus(Duration.ofHours(rule.dueHours()));
        var existing = activeTasks.get(livestockId);
        var healthSignal = healthData(snapshot, healthAlertLivestock.contains(livestockId));
        return new EpidemicLivestockWorkbenchItem(
                livestockId.toString(), code(livestockId), null,
                rule.tier().name(), rule.tier().getRank(),
                rule.action().name(),
                existing == null ? EpidemicDispositionStatus.PENDING.name() : existing.getStatus().name(),
                existing == null ? null : existing.getId(),
                existing == null ? dueAt : existing.getDueAt(),
                direct != null, depth,
                (int) related.stream().map(event -> event.from().livestockId() + "->" + event.to().livestockId())
                        .distinct().count(),
                maxRisk, riskLevel(maxRisk), lastContact,
                lastContact == null ? null : (int) Duration.between(lastContact, now).toMinutes(),
                healthSignal, reasons.stream().distinct().toList(),
                eventIdsByAnimal.getOrDefault(livestockId.toString(), List.of()).stream()
                        .toList(),
                graph.paths.get(livestockId).edges().stream().map(String::valueOf).toList()
        );
    }

    private Classification classify(EpidemicEventItem direct, int directAgeHours, int maxRisk,
                                    int depth, boolean health) {
        if (direct != null && directAgeHours <= 24 && maxRisk >= criticalRisk && health) {
            return new Classification(EpidemicDispositionTier.CRITICAL,
                    EpidemicDispositionAction.ISOLATE_NOTIFY_VET, Instant.now().plus(Duration.ofHours(2)));
        }
        if (direct != null && directAgeHours <= 24 && maxRisk >= criticalNoHealthRisk) {
            return new Classification(EpidemicDispositionTier.CRITICAL,
                    EpidemicDispositionAction.IMMEDIATE_VET_CHECK, Instant.now().plus(Duration.ofHours(4)));
        }
        if ((direct != null && directAgeHours <= 48 && maxRisk >= observationRisk)
                || (depth <= 2 && maxRisk >= criticalRisk)) {
            return new Classification(EpidemicDispositionTier.OBSERVATION,
                    EpidemicDispositionAction.HEALTH_RECHECK, Instant.now().plus(Duration.ofHours(24)));
        }
        if (maxRisk >= observationRisk || depth <= 2) {
            return new Classification(EpidemicDispositionTier.TRACKING,
                    EpidemicDispositionAction.CONTINUE_TRACING, Instant.now().plus(Duration.ofHours(72)));
        }
        return new Classification(EpidemicDispositionTier.ARCHIVE,
                EpidemicDispositionAction.ARCHIVE_ONLY, null);
    }

    private boolean directSourceClassification(EpidemicEventItem direct, int directAgeHours,
                                               int maxRisk, boolean health) {
        return direct != null && directAgeHours <= 24 && maxRisk >= criticalRisk
                && (health || maxRisk >= criticalNoHealthRisk);
    }

    private boolean isDirectSource(EpidemicEventItem event, Long sourceId) {
        return sourceId.toString().equals(event.from().livestockId())
                || sourceId.toString().equals(event.to().livestockId());
    }

    private Map<String, List<Long>> eventIdsByAnimal(List<EpidemicEventItem> events, Long sourceId) {
        Map<String, List<Long>> result = new HashMap<>();
        for (EpidemicEventItem event : events) {
            result.computeIfAbsent(event.from().livestockId(), ignored -> new ArrayList<>()).add(event.eventId());
            result.computeIfAbsent(event.to().livestockId(), ignored -> new ArrayList<>()).add(event.eventId());
        }
        result.remove(sourceId.toString());
        return result;
    }

    private Map<Long, EpidemicDispositionJpaEntity> activeTasksByLivestock(Long farmId) {
        return dispositionRepository.findByFarmIdAndStatusIn(
                        farmId, List.of(EpidemicDispositionStatus.PENDING, EpidemicDispositionStatus.IN_PROGRESS))
                .stream().collect(Collectors.toMap(
                        EpidemicDispositionJpaEntity::getLivestockId, Function.identity(), (l, r) -> l));
    }

    private List<EpidemicTierSummary> tierSummaries(List<EpidemicLivestockWorkbenchItem> items) {
        return Arrays.stream(EpidemicDispositionTier.values())
                .map(tier -> new EpidemicTierSummary(
                        tier.name(), tier.getRank(),
                        (int) items.stream().filter(item -> item.dispositionTier().equals(tier.name())).count()))
                .toList();
    }

    private Set<String> parseTiers(String tierCsv) {
        if (tierCsv == null || tierCsv.isBlank()) return Set.of();
        Set<String> values = Arrays.stream(tierCsv.split(","))
                .map(value -> value.trim().toUpperCase(Locale.ROOT)).collect(Collectors.toSet());
        values.removeAll(Set.of("CRITICAL", "OBSERVATION", "TRACKING", "ARCHIVE"));
        if (!values.isEmpty()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "validation.epidemicTierInvalid");
        }
        return Arrays.stream(tierCsv.split(","))
                .map(value -> value.trim().toUpperCase(Locale.ROOT)).collect(Collectors.toSet());
    }

    private EpidemicDispositionAction parseAction(String requested, String recommended) {
        String value = (requested == null || requested.isBlank()) ? recommended : requested;
        try {
            return EpidemicDispositionAction.valueOf(value.toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "validation.epidemicActionInvalid");
        }
    }

    private EpidemicDispositionResponse toResponse(EpidemicDispositionJpaEntity entity) {
        return new EpidemicDispositionResponse(
                entity.getId(), entity.getLivestockId().toString(),
                entity.getSourceLivestockId() == null ? null : entity.getSourceLivestockId().toString(),
                entity.getTier().name(), entity.getActionCode().name(), entity.getStatus().name(),
                entity.getReasonCodes(), entity.getDueAt(), entity.getCompletedAt()
        );
    }

    private EpidemicHealthSignal healthData(HealthSnapshot snapshot, boolean activeAlert) {
        return new EpidemicHealthSignal(
                snapshot == null ? null : snapshot.getCurrentTemp(),
                snapshot == null || snapshot.getTempStatus() == null ? null : snapshot.getTempStatus().name(),
                snapshot == null || snapshot.getMotilityStatus() == null ? null : snapshot.getMotilityStatus().name(),
                activeAlert,
                snapshot == null ? null : snapshot.getAiAnomalyScore()
        );
    }

    private boolean hasHealthSignal(HealthSnapshot snapshot, boolean activeAlert) {
        return activeAlert
                || (snapshot != null && snapshot.getTempStatus() != null
                && (snapshot.getTempStatus() == TempStatus.FEVER
                || snapshot.getTempStatus() == TempStatus.CRITICAL))
                || (snapshot != null && snapshot.getMotilityStatus() != null
                && snapshot.getMotilityStatus().name().equals("ABNORMAL"));
    }

    private List<String> factors(ContactTrace trace, Instant now) {
        List<String> values = new ArrayList<>();
        if (trace.getLastContactAt() != null) {
            long hours = Duration.between(trace.getLastContactAt(), now).toHours();
            if (hours <= 24) values.add("FRESH");
            if (hours <= 48) values.add("RECENT");
        }
        double distance = trace.getProximityMeters() == null ? 0 : trace.getProximityMeters().doubleValue();
        if (distance < 5) values.add("NEAR");
        else if (distance < 15) values.add("MODERATE_DISTANCE");
        int duration = trace.getContactDurationMinutes() == null ? 0 : trace.getContactDurationMinutes();
        if (duration > 30) values.add("LONG_DURATION");
        else if (duration > 15) values.add("MEDIUM_DURATION");
        return values;
    }

    private int timeScore(Instant contactAt, Instant now) {
        if (contactAt == null) return 5;
        long hours = Duration.between(contactAt, now).toHours();
        if (hours <= 24) return 40;
        if (hours <= 48) return 25;
        return 12;
    }

    private int distanceScore(java.math.BigDecimal proximity) {
        if (proximity == null) return 5;
        double value = proximity.doubleValue();
        if (value < 5) return 35;
        if (value < 15) return 25;
        if (value < 30) return 15;
        return 5;
    }

    private int durationScore(Integer duration) {
        if (duration == null) return 3;
        if (duration > 30) return 25;
        if (duration > 15) return 18;
        if (duration > 5) return 10;
        return 3;
    }

    private String riskLevel(int score) {
        return score >= 70 ? "HIGH" : score >= 40 ? "MEDIUM" : "LOW";
    }

    private String code(Long livestockId) {
        return ranchQueryPort.findLivestockById(livestockId)
                .map(LivestockInfo::livestockCode).orElse("?");
    }

    private record Classification(EpidemicDispositionTier tier,
                                  EpidemicDispositionAction action,
                                  Instant dueAt) {}

    private record PathData(List<Long> nodes, List<Long> edges, int riskScore) {
        private PathData append(Long node, Long edge, int score) {
            List<Long> nextNodes = new ArrayList<>(nodes);
            List<Long> nextEdges = new ArrayList<>(edges);
            nextNodes.add(node);
            nextEdges.add(edge);
            return new PathData(nextNodes, nextEdges, riskScore + score);
        }
    }

    private record GraphResult(Long sourceId,
                               Map<Long, Integer> depths,
                               Map<Long, PathData> paths,
                               Map<Long, EpidemicEventItem> eventById,
                               int maxDepth) {
        private EpidemicNetworkGraph graph(String sourceCode,
                                           Function<Long, String> codeResolver,
                                           Map<Long, EpidemicLivestockWorkbenchItem> livestockById) {
            List<EpidemicGraphNode> nodes = new ArrayList<>();
            nodes.add(new EpidemicGraphNode(sourceId.toString(), sourceCode, "SOURCE", null));
            depths.keySet().stream().filter(id -> !id.equals(sourceId)).sorted()
                    .forEach(id -> nodes.add(new EpidemicGraphNode(
                            id.toString(), codeResolver.apply(id), "CONTACT",
                            livestockById.get(id) == null ? null : livestockById.get(id).dispositionTier())));
            Set<Long> usedEdgeIds = paths.values().stream()
                    .flatMap(path -> path.edges().stream())
                    .collect(Collectors.toSet());
            List<EpidemicGraphEdge> edges = eventById.keySet().stream()
                    .filter(usedEdgeIds::contains)
                    .map(eventById::get)
                    .map(event -> {
                        Long other = event.from().livestockId().equals(sourceId.toString())
                                ? Long.valueOf(event.to().livestockId())
                                : Long.valueOf(event.from().livestockId());
                        return new EpidemicGraphEdge(String.valueOf(event.eventId()),
                                event.from().livestockId(), event.to().livestockId(), event.eventId(),
                                depths.getOrDefault(other, 1), event.riskScore(), event.riskLevel());
                    })
                    .toList();
            List<EpidemicGraphPath> paths = this.paths.entrySet().stream()
                    .filter(entry -> !entry.getValue().nodes().isEmpty())
                    .map(entry -> new EpidemicGraphPath(
                            "P-" + entry.getKey(), entry.getValue().nodes().stream().map(String::valueOf).toList(),
                            entry.getValue().edges().stream().map(String::valueOf).toList(),
                            entry.getValue().edges().size(), entry.getValue().riskScore(),
                            staticRiskLevel(entry.getValue().riskScore())))
                    .toList();
            return new EpidemicNetworkGraph(sourceId.toString(), maxDepth, nodes, edges, paths);
        }

        private static String staticRiskLevel(int score) {
            return score >= 70 ? "HIGH" : score >= 40 ? "MEDIUM" : "LOW";
        }
    }
}
