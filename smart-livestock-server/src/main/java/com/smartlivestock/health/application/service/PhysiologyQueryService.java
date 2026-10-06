package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.EpidemicDispositionJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Read-time merge implementation of {@link PhysiologyQueryPort} (NIX-256).
 * <p>
 * Illness windows are the UNION of two lanes — the epidemic workbench stays
 * untouched (zero hooks, zero sync); its disposition table is only read here:
 * <ul>
 *   <li>MANUAL lane: physiology_events ILLNESS/RECOVERY rows paired by stack
 *       matching; an unpaired illness stays open ({@code endedAt == null});
 *       a recovery never forms a window on its own.</li>
 *   <li>DISPOSITION lane: PENDING/IN_PROGRESS → [created_at, null);
 *       COMPLETED → [created_at, completed_at]; CANCELLED (including
 *       SOURCE_UNMARKED soft delete) → no window.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class PhysiologyQueryService implements PhysiologyQueryPort {

    static final String SOURCE_TYPE_MANUAL = "MANUAL";
    static final String SOURCE_TYPE_DISPOSITION = "DISPOSITION";

    private static final List<PhysiologyEventType> ILLNESS_LANE_TYPES =
            List.of(PhysiologyEventType.ILLNESS, PhysiologyEventType.RECOVERY);
    private static final List<PhysiologyEventType> STAGE_TYPES =
            List.of(PhysiologyEventType.CALVING, PhysiologyEventType.DRY_OFF);

    private final PhysiologyEventJpaRepository eventRepository;
    private final EpidemicDispositionJpaRepository dispositionRepository;
    private final RanchQueryPort ranchQueryPort;

    /** Industry lactation length before implicit dry-off; configurable (F7). */
    @Value("${health.physiology.lactation-length-days:305}")
    private int lactationLengthDays;

    // ── Manual-lane pairing ─────────────────────────────────────

    /** Minimal event projection for pairing; input order is irrelevant. */
    record TimedEvent(PhysiologyEventType eventType, Instant occurredAt) {}

    /** Paired illness window; {@code endedAt == null} while the illness is ongoing. */
    record PairedWindow(Instant occurredAt, Instant endedAt) {}

    /**
     * Stack pairing of manual ILLNESS/RECOVERY rows. Events are first sorted
     * chronologically (so out-of-order entry self-corrects); each RECOVERY
     * closes the most recent still-open ILLNESS (LIFO, nested pairs close
     * inner-first). Surplus recoveries with no open illness are ignored, and
     * leftover illnesses stay open-ended. Package-visible for pure unit tests.
     */
    static List<PairedWindow> pairIllnessRecovery(List<TimedEvent> events) {
        List<TimedEvent> sorted = events.stream()
                .sorted(Comparator.comparing(TimedEvent::occurredAt)
                        // At equal instants an ILLNESS sorts before its RECOVERY
                        // so a same-day pair still closes.
                        .thenComparingInt(e -> e.eventType() == PhysiologyEventType.ILLNESS ? 0 : 1))
                .toList();
        Deque<Instant> open = new ArrayDeque<>();
        List<PairedWindow> windows = new ArrayList<>();
        for (TimedEvent event : sorted) {
            if (event.eventType() == PhysiologyEventType.ILLNESS) {
                open.push(event.occurredAt());
            } else if (event.eventType() == PhysiologyEventType.RECOVERY && !open.isEmpty()) {
                windows.add(new PairedWindow(open.pop(), event.occurredAt()));
            }
        }
        open.forEach(start -> windows.add(new PairedWindow(start, null)));
        windows.sort(Comparator.comparing(PairedWindow::occurredAt));
        return windows;
    }

    // ── PhysiologyQueryPort ─────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<PhysiologyWindow> activeWindows(Long livestockId, Instant from, Instant to) {
        Range range = Range.of(from, to);
        List<TimedEvent> history = eventRepository
                .findByLivestockIdAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
                        livestockId, ILLNESS_LANE_TYPES, PhysiologySource.MANUAL, range.to())
                .stream()
                .map(e -> new TimedEvent(e.getEventType(), e.getOccurredAt()))
                .toList();
        List<PhysiologyWindow> windows = new ArrayList<>();
        pairIllnessRecovery(history).stream()
                .filter(w -> overlaps(w.occurredAt(), w.endedAt(), range))
                .forEach(w -> windows.add(new PhysiologyWindow(
                        PhysiologyEventType.ILLNESS, w.occurredAt(), w.endedAt(),
                        SOURCE_TYPE_MANUAL, null)));
        dispositionRepository.findByLivestockId(livestockId).stream()
                .flatMap(d -> dispositionWindow(d).stream())
                .filter(w -> overlaps(w.occurredAt(), w.endedAt(), range))
                .forEach(windows::add);
        windows.sort(Comparator.comparing(PhysiologyWindow::occurredAt));
        return windows;
    }

    @Override
    @Transactional(readOnly = true)
    public Map<Long, List<PhysiologyWindow>> activeWindowsForFarm(Long farmId, Instant from, Instant to) {
        Range range = Range.of(from, to);
        List<Long> livestockIds = ranchQueryPort.findAllByFarmId(farmId).stream()
                .map(LivestockInfo::id)
                .toList();
        if (livestockIds.isEmpty()) {
            return Map.of();
        }
        // Batch both lanes once for the whole herd to avoid N+1.
        Map<Long, List<TimedEvent>> historyByLivestock = new HashMap<>();
        eventRepository.findByLivestockIdInAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
                        livestockIds, ILLNESS_LANE_TYPES, PhysiologySource.MANUAL, range.to())
                .forEach(e -> historyByLivestock
                        .computeIfAbsent(e.getLivestockId(), ignored -> new ArrayList<>())
                        .add(new TimedEvent(e.getEventType(), e.getOccurredAt())));
        Map<Long, List<EpidemicDispositionJpaEntity>> dispositionsByLivestock = new HashMap<>();
        dispositionRepository.findByLivestockIdIn(livestockIds)
                .forEach(d -> dispositionsByLivestock
                        .computeIfAbsent(d.getLivestockId(), ignored -> new ArrayList<>())
                        .add(d));

        Map<Long, List<PhysiologyWindow>> result = new LinkedHashMap<>();
        for (Long livestockId : livestockIds) {
            List<PhysiologyWindow> windows = new ArrayList<>();
            pairIllnessRecovery(historyByLivestock.getOrDefault(livestockId, List.of())).stream()
                    .filter(w -> overlaps(w.occurredAt(), w.endedAt(), range))
                    .forEach(w -> windows.add(new PhysiologyWindow(
                            PhysiologyEventType.ILLNESS, w.occurredAt(), w.endedAt(),
                            SOURCE_TYPE_MANUAL, null)));
            dispositionsByLivestock.getOrDefault(livestockId, List.of()).stream()
                    .flatMap(d -> dispositionWindow(d).stream())
                    .filter(w -> overlaps(w.occurredAt(), w.endedAt(), range))
                    .forEach(windows::add);
            if (!windows.isEmpty()) {
                windows.sort(Comparator.comparing(PhysiologyWindow::occurredAt));
                result.put(livestockId, windows);
            }
        }
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<PhysiologyStage> currentStage(Long livestockId) {
        return eventRepository.findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                        livestockId, STAGE_TYPES, PhysiologySource.MANUAL)
                // Defensive filter (NIX-258 m-p): only MANUAL milestones drive
                // the stage. The repository query already pins source=MANUAL;
                // this guards against a future ALERT_CONFIRM write path
                // slipping rows past the query (e.g. someone reverts to a
                // source-less finder) — a confirmed-alert CALVING/DRY_OFF is
                // read-only history and must not shift the projection.
                .filter(latest -> latest.getSource() == PhysiologySource.MANUAL)
                .map(latest -> {
                    if (latest.getEventType() == PhysiologyEventType.DRY_OFF) {
                        return new PhysiologyStage(PhysiologyStageType.DRY, latest.getOccurredAt());
                    }
                    // CALVING is the latest milestone. Industry convention:
                    // cows are milked ~305 days after calving and then dried
                    // off; past that horizon the animal is implicitly DRY
                    // since calving + lactation-length-days (configurable, F7).
                    Instant calvingAt = latest.getOccurredAt();
                    Instant implicitDryAt = calvingAt.plus(Duration.ofDays(lactationLengthDays));
                    if (Instant.now().isAfter(implicitDryAt)) {
                        return new PhysiologyStage(PhysiologyStageType.DRY, implicitDryAt);
                    }
                    return new PhysiologyStage(PhysiologyStageType.LACTATING, calvingAt);
                });
    }

    // ── Helpers ─────────────────────────────────────────────────

    /**
     * Disposition lane projection: PENDING/IN_PROGRESS is an open window from
     * creation; COMPLETED ends at completed_at; CANCELLED (any reason,
     * including the SOURCE_UNMARKED soft delete) yields no window.
     */
    private Optional<PhysiologyWindow> dispositionWindow(EpidemicDispositionJpaEntity disposition) {
        return switch (disposition.getStatus()) {
            case PENDING, IN_PROGRESS -> Optional.of(new PhysiologyWindow(
                    PhysiologyEventType.ILLNESS, disposition.getCreatedAt(), null,
                    SOURCE_TYPE_DISPOSITION, disposition.getId()));
            case COMPLETED -> Optional.of(new PhysiologyWindow(
                    PhysiologyEventType.ILLNESS, disposition.getCreatedAt(),
                    disposition.getCompletedAt(), SOURCE_TYPE_DISPOSITION, disposition.getId()));
            case CANCELLED -> Optional.empty();
        };
    }

    /** Window [start, end) intersects [range.from, range.to); open end counts as intersecting. */
    private static boolean overlaps(Instant start, Instant end, Range range) {
        return start.isBefore(range.to()) && (end == null || end.isAfter(range.from()));
    }

    /**
     * Query range with null guards. {@code from} only filters in memory
     * (EPOCH is safe); {@code to} is also a bind parameter so null collapses
     * to now() — manual events can never be future-dated (write validation).
     */
    private record Range(Instant from, Instant to) {
        static Range of(Instant from, Instant to) {
            return new Range(from == null ? Instant.EPOCH : from, to == null ? Instant.now() : to);
        }
    }
}
