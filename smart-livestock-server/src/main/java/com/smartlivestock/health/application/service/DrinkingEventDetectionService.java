package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.DrinkingAlgorithmVersion;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyWindow;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Drinking-event detection and recalculation (NIX-256 Task 3).
 *
 * <p>The judging core is a set of package-visible <b>static pure functions</b>
 * (no Spring, no IO) so the semantics stay unit-testable in isolation —
 * same convention as {@code PhysiologyQueryService.pairIllnessRecovery}.
 * The instance methods are a thin shell doing queries and persistence.
 *
 * <p>Detector contract (spec §4 + §14 calibrated params, user ruling
 * 2026-10-05): a confirmed event is a temperature valley passing ALL of —
 * <ol>
 *   <li><b>slope</b>: an adjacent in-body point pair inside the descent with
 *       {@code fall/Δt_min ≥ fall-threshold} (Δt normalized; pairs with
 *       Δt ≤ 0 or &gt; 30 min are skipped as out-of-order points);</li>
 *   <li><b>depth</b>: trough below the same-local-day baseline
 *       {@code μ_day − k·σ_day} (cow-day = Asia/Shanghai calendar day, F5);</li>
 *   <li><b>recovery</b>: within {@code recovery-window-min} after the trough
 *       the temperature rises at least {@code recovery-ratio × D} with
 *       {@code D = start temp − trough temp}.</li>
 * </ol>
 * Trough = end of the first descending segment after the trigger point.
 * Confirmed events whose starts are less than {@code merge-gap-min} apart
 * chain-merge (earliest start, deepest trough, largest drop). Valleys that
 * fail but keep every criterion ratio r_i ≥ {@code candidate-tolerance}
 * become borderline candidates (source ALGORITHM_CANDIDATE, never merged).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DrinkingEventDetectionService {

    /** Ranch operating timezone; the cow-day boundary (F5). */
    public static final ZoneId COW_DAY_ZONE = ZoneId.of("Asia/Shanghai");

    /** In-body temperature gate, shared with the ingestion plausibility band (35–43°C). */
    static final double IN_BODY_MIN_TEMP = 35.0;
    static final double IN_BODY_MAX_TEMP = 43.0;

    /** Fixed depth reference for the confidence heuristic (°C). */
    static final double DEPTH_CONFIDENCE_THRESHOLD_C = 1.0;

    /** Context window before each cow-day midnight (spec F5 2h prefix). */
    static final Duration DAY_PREFIX = Duration.ofHours(2);

    /** Pairs farther apart than this are not "adjacent" for slope purposes. */
    static final Duration MAX_ADJACENT_GAP = Duration.ofMinutes(30);

    private static final List<String> FEVER_ALERT_TYPES = List.of("TEMPERATURE_ABNORMAL");

    private final TemperatureLogJpaRepository temperatureLogJpaRepository;
    private final DrinkingEventJpaRepository drinkingEventJpaRepository;
    private final PhysiologyQueryPort physiologyQueryPort;
    private final RanchQueryPort ranchQueryPort;
    private final DeviceQueryPort deviceQueryPort;

    // ── Calibrated parameters (spec §14; all configurable, F3) ───

    @Value("${health.drinking.fall-threshold:0.06}")
    private double fallThreshold;
    @Value("${health.drinking.k-sigma:0.5}")
    private double kSigma;
    @Value("${health.drinking.recovery-window-min:120}")
    private int recoveryWindowMin;
    @Value("${health.drinking.recovery-ratio:0.7}")
    private double recoveryRatio;
    @Value("${health.drinking.merge-gap-min:15}")
    private int mergeGapMin;
    @Value("${health.drinking.candidate-tolerance:0.5}")
    private double candidateTolerance;
    @Value("${health.drinking.fever-buffer-hours:6}")
    private long feverBufferHours;
    @Value("${health.drinking.recalc-overlap-hours:1}")
    private int recalcOverlapHours;

    // ════════════════════════════════════════════════════════════
    // Pure kernel — package-visible static functions
    // ════════════════════════════════════════════════════════════

    /** One temperature sample of a device (source passthrough, §4). */
    record TempPoint(Instant at, double temperature, String source) {}

    /**
     * Raw exclusion window before the fever buffer is applied.
     * {@code end == null} means still open (active illness / active alert).
     */
    record ExclusionWindow(Instant start, Instant end) {}

    /** All judging parameters; defaults = spec §14 L1 calibration. */
    record Params(double fallThreshold, double kSigma, int recoveryWindowMin,
                  double recoveryRatio, int mergeGapMin, double candidateTolerance,
                  long feverBufferHours, int recalcOverlapHours) {

        static Params defaults() {
            return new Params(0.06, 0.5, 120, 0.7, 15, 0.5, 6, 1);
        }
    }

    /** A judged valley: confirmed event or borderline candidate. */
    record Valley(Instant startAt, Instant troughAt, double tempDrop, double minTemp,
                  double confidence, String source,
                  double rSlope, double rDepth, double rRecovery) {}

    /** Detection output: confirmed (merged) events + borderline candidates. */
    record DetectionResult(List<Valley> events, List<Valley> candidates) {
        static final DetectionResult EMPTY = new DetectionResult(List.of(), List.of());
    }

    /**
     * Scan {@code [rangeFrom, rangeTo)} for one device. Points are gated to
     * the in-body band and grouped per Asia/Shanghai calendar day; each day
     * is judged with its own μ/σ over a scan slice extended by a 2h prefix
     * (midnight-crossing descents) and a recovery-window lookahead
     * (late-evening recoveries). A valley belongs to the local day of its
     * START — that day's scan sees it in full and every other day's scan
     * discards it, so nothing is double counted. Confirmed events are then
     * merged globally (chains may straddle midnight) and buffered exclusion
     * windows drop valleys whose start or trough falls inside them.
     * Candidates are deduplicated per trough and never merged.
     */
    static DetectionResult detectRange(List<TempPoint> rawPoints, ZoneId zone,
                                       Instant rangeFrom, Instant rangeTo,
                                       List<ExclusionWindow> rawWindows, Params params) {
        List<TempPoint> points = rawPoints.stream()
                .filter(p -> p.temperature() >= IN_BODY_MIN_TEMP && p.temperature() <= IN_BODY_MAX_TEMP)
                .sorted(Comparator.comparing(TempPoint::at))
                .toList();
        List<ExclusionWindow> windows = extendWindows(rawWindows, params.feverBufferHours());
        if (points.isEmpty() || !rangeFrom.isBefore(rangeTo)) {
            return DetectionResult.EMPTY;
        }

        Duration recoveryLookahead = Duration.ofMinutes(params.recoveryWindowMin());
        List<Valley> rawEvents = new ArrayList<>();
        Map<Instant, Valley> candidateByTrough = new LinkedHashMap<>();
        LocalDate day = LocalDate.ofInstant(rangeFrom, zone);
        LocalDate lastDay = LocalDate.ofInstant(rangeTo.minusNanos(1), zone);
        while (!day.isAfter(lastDay)) {
            Instant dayStart = day.atStartOfDay(zone).toInstant();
            Instant dayEnd = day.plusDays(1).atStartOfDay(zone).toInstant();
            List<TempPoint> dayPoints = slice(points, dayStart, dayEnd);
            if (dayPoints.size() >= 2) {
                double mu = mean(dayPoints);
                double sigma = stddev(dayPoints, mu);
                List<TempPoint> scanSlice = slice(points,
                        dayStart.minus(DAY_PREFIX), dayEnd.plus(recoveryLookahead));
                DayJudgement judged = judgeDay(scanSlice, mu, sigma, params);
                Instant keepFrom = dayStart.isBefore(rangeFrom) ? rangeFrom : dayStart;
                Instant keepTo = dayEnd.isAfter(rangeTo) ? rangeTo : dayEnd;
                for (Valley valley : judged.events()) {
                    if (!valley.startAt().isBefore(keepFrom) && valley.startAt().isBefore(keepTo)) {
                        rawEvents.add(valley);
                    }
                }
                for (Valley candidate : judged.candidates()) {
                    if (!candidate.startAt().isBefore(keepFrom) && candidate.startAt().isBefore(keepTo)) {
                        // One physical valley must yield one candidate row: dips
                        // triggered by several near-threshold pairs inside one
                        // descent share the trough — keep the earliest start.
                        candidateByTrough.merge(candidate.troughAt(), candidate,
                                (a, b) -> a.startAt().isBefore(b.startAt()) ? a : b);
                    }
                }
            }
            day = day.plusDays(1);
        }

        List<Valley> events = excludeDropped(mergeEvents(rawEvents, params.mergeGapMin()), windows);
        List<Valley> candidates = excludeDropped(new ArrayList<>(candidateByTrough.values()), windows);
        return new DetectionResult(events, candidates);
    }

    /** Per-day judging output before merge and exclusion. */
    private record DayJudgement(List<Valley> events, List<Valley> candidates) {}

    private static DayJudgement judgeDay(List<TempPoint> slice, double mu, double sigma, Params params) {
        double depthLine = mu - params.kSigma() * sigma;
        List<Valley> events = new ArrayList<>();
        List<Valley> candidates = new ArrayList<>();
        for (int i = 1; i < slice.size(); i++) {
            double dtMin = minutesBetween(slice.get(i - 1).at(), slice.get(i).at());
            if (dtMin <= 0 || dtMin > MAX_ADJACENT_GAP.toMinutes()) {
                continue; // out-of-order or gapped pair
            }
            double fall = slice.get(i - 1).temperature() - slice.get(i).temperature();
            if (fall <= 0) {
                continue; // not a descent step
            }
            double fallRate = fall / dtMin;
            // Proto-dips form at the candidate-tolerance level so borderline
            // valleys (r_slope ≥ tolerance but < 1) are still evaluated.
            if (fallRate < params.fallThreshold() * params.candidateTolerance()) {
                continue;
            }
            Valley valley = judgeValley(slice, i, depthLine, params);
            if (valley == null) {
                continue;
            }
            boolean confirmed = valley.rSlope() >= 1 && valley.rDepth() >= 1 && valley.rRecovery() >= 1;
            boolean borderline = valley.rSlope() >= params.candidateTolerance()
                    && valley.rDepth() >= params.candidateTolerance()
                    && valley.rRecovery() >= params.candidateTolerance();
            if (confirmed) {
                events.add(valley);
            } else if (borderline) {
                candidates.add(valley);
            }
        }
        return new DayJudgement(events, candidates);
    }

    /**
     * Judge the valley triggered at pair {@code (i-1, i)}: the start is the
     * pre-fall point; the trough is the end of the first descending segment
     * (the run stops when the temperature stops falling or the series is
     * broken by an invalid Δt); slope/depth/recovery margins follow. Returns
     * null when the shape degenerates.
     */
    private static Valley judgeValley(List<TempPoint> slice, int i, double depthLine, Params params) {
        TempPoint start = slice.get(i - 1);
        int j = i;
        while (j + 1 < slice.size()) {
            double dtMin = minutesBetween(slice.get(j).at(), slice.get(j + 1).at());
            if (dtMin <= 0 || dtMin > MAX_ADJACENT_GAP.toMinutes()) {
                break; // series gap terminates the descending segment
            }
            if (slice.get(j + 1).temperature() < slice.get(j).temperature()) {
                j++;
            } else {
                break;
            }
        }
        TempPoint trough = slice.get(j);
        double drop = start.temperature() - trough.temperature();
        if (drop <= 0) {
            return null;
        }

        // Slope achievement: steepest valid adjacent rate inside the descent.
        double maxRate = 0;
        for (int k = i - 1; k < j; k++) {
            double dtMin = minutesBetween(slice.get(k).at(), slice.get(k + 1).at());
            if (dtMin <= 0 || dtMin > MAX_ADJACENT_GAP.toMinutes()) {
                continue;
            }
            maxRate = Math.max(maxRate,
                    (slice.get(k).temperature() - slice.get(k + 1).temperature()) / dtMin);
        }
        double rSlope = maxRate / params.fallThreshold();

        // Depth achievement: how far below μ−kσ the trough sits (1.0°C reference).
        double rDepth = (depthLine - trough.temperature()) / DEPTH_CONFIDENCE_THRESHOLD_C;

        // Recovery achievement: best rise within the recovery window after the trough.
        Instant deadline = trough.at().plus(Duration.ofMinutes(params.recoveryWindowMin()));
        double bestRise = 0;
        for (int k = j + 1; k < slice.size() && !slice.get(k).at().isAfter(deadline); k++) {
            bestRise = Math.max(bestRise, slice.get(k).temperature() - trough.temperature());
        }
        double recoveryThreshold = params.recoveryRatio() * drop;
        double rRecovery = recoveryThreshold > 0 ? bestRise / recoveryThreshold : 1;

        // Confidence heuristic v1: margin ratios normalized to [0,1] via
        // clamp01(r/2) and averaged. Deliberately simple and monotone —
        // recalibrate only with labeled data (spec §15.4), never ad hoc.
        double confidence = (clamp01(rSlope / 2) + clamp01(rDepth / 2) + clamp01(rRecovery / 2)) / 3;
        return new Valley(start.at(), trough.at(), drop, trough.temperature(),
                confidence, start.source(), rSlope, rDepth, rRecovery);
    }

    /**
     * Chain-merge confirmed events whose consecutive starts are closer than
     * {@code mergeGapMin} minutes: earliest start, deepest trough, largest
     * drop, highest confidence; source = earliest start's point source.
     *
     * <p>The gap compares against the <b>previous member's own start</b>
     * (rolling anchor), not the merged chain's earliest start: a descent
     * longer than the merge gap emits one candidate per qualifying step, and
     * a chain-first anchor would slice that single valley into phantom
     * segments at exact merge-gap multiples (T6 replay finding, 2026-10-05).
     */
    static List<Valley> mergeEvents(List<Valley> valleys, int mergeGapMin) {
        List<Valley> sorted = valleys.stream()
                .sorted(Comparator.comparing(Valley::startAt))
                .toList();
        List<Valley> merged = new ArrayList<>();
        Instant lastMemberStart = null;
        for (Valley valley : sorted) {
            if (lastMemberStart != null && minutesBetween(lastMemberStart, valley.startAt()) < mergeGapMin) {
                merged.set(merged.size() - 1, combine(merged.get(merged.size() - 1), valley));
            } else {
                merged.add(valley);
            }
            lastMemberStart = valley.startAt();
        }
        return merged;
    }

    private static Valley combine(Valley a, Valley b) {
        Valley deepest = a.minTemp() <= b.minTemp() ? a : b;
        Valley earliest = a.startAt().isBefore(b.startAt()) ? a : b;
        return new Valley(
                earliest.startAt(),
                deepest.troughAt(),
                Math.max(a.tempDrop(), b.tempDrop()),
                deepest.minTemp(),
                Math.max(a.confidence(), b.confidence()),
                earliest.source(),
                Math.max(a.rSlope(), b.rSlope()),
                Math.max(a.rDepth(), b.rDepth()),
                Math.max(a.rRecovery(), b.rRecovery()));
    }

    /** Drop valleys whose start or trough falls inside any (buffered) window. */
    private static List<Valley> excludeDropped(List<Valley> valleys, List<ExclusionWindow> windows) {
        if (windows.isEmpty()) {
            return valleys;
        }
        return valleys.stream()
                .filter(v -> windows.stream().noneMatch(w -> covers(w, v.startAt()) || covers(w, v.troughAt())))
                .toList();
    }

    private static boolean covers(ExclusionWindow window, Instant at) {
        return !at.isBefore(window.start())
                && (window.end() == null || at.isBefore(window.end()));
    }

    /**
     * Fever/defervescence buffer: every window end extends by
     * {@code feverBufferHours}; open windows stay open. The defervescence
     * tail is the more dangerous false-positive source than the fever
     * itself — the temperature falls back into the normal band while the
     * day's μ/σ are still inflated (tech doc §4.2.3).
     */
    static List<ExclusionWindow> extendWindows(List<ExclusionWindow> windows, long feverBufferHours) {
        Duration buffer = Duration.ofHours(feverBufferHours);
        return windows.stream()
                .map(w -> new ExclusionWindow(w.start(),
                        w.end() == null ? null : w.end().plus(buffer)))
                .toList();
    }

    private static List<TempPoint> slice(List<TempPoint> points, Instant from, Instant to) {
        return points.stream()
                .filter(p -> !p.at().isBefore(from) && p.at().isBefore(to))
                .toList();
    }

    private static double mean(List<TempPoint> points) {
        return points.stream().mapToDouble(TempPoint::temperature).average().orElse(0);
    }

    private static double stddev(List<TempPoint> points, double mean) {
        double variance = points.stream()
                .mapToDouble(p -> (p.temperature() - mean) * (p.temperature() - mean))
                .average().orElse(0);
        return Math.sqrt(variance);
    }

    static double minutesBetween(Instant from, Instant to) {
        return Duration.between(from, to).toNanos() / 60_000_000_000.0;
    }

    private static double clamp01(double value) {
        return Math.min(1, Math.max(0, value));
    }

    // ════════════════════════════════════════════════════════════
    // Application shell — queries and persistence
    // ════════════════════════════════════════════════════════════

    private Params currentParams() {
        // Spec §4: k > 2 already breaks the F ≥ 0.90 gate (k=3 → 0.8317) —
        // surface misconfiguration loudly instead of silently degrading.
        if (kSigma > 2) {
            log.warn("health.drinking.k-sigma={} exceeds the calibrated safe range (k>2 breaks F>=0.90)", kSigma);
        }
        return new Params(fallThreshold, kSigma, recoveryWindowMin, recoveryRatio,
                mergeGapMin, candidateTolerance, feverBufferHours, recalcOverlapHours);
    }

    /**
     * Recalculate one device over {@code [from, to)} (F6): delete algorithm
     * rows in the overlap-extended window, re-derive from temperature_logs,
     * re-insert with the §15.4 label snapshot restored. Entry point for the
     * T4 daily scheduler and the admin recalculate API.
     *
     * @return sweep statistics for batch summaries (NIX-256 Task 4)
     */
    @Transactional
    public RecalcStats recalculateDevice(Long deviceId, Instant from, Instant to) {
        CapsuleBinding binding = deviceQueryPort.findActiveCapsuleBindingByDeviceId(deviceId).orElse(null);
        int rows = recalculate(deviceId, binding != null ? binding.livestockId() : null, from, to, null);
        return new RecalcStats(1, rows);
    }

    /**
     * Recalculate every actively-installed capsule of a farm over
     * {@code [from, to)}. Exclusion windows are fetched once per herd (B4)
     * instead of per device.
     *
     * @return sweep statistics for batch summaries (NIX-256 Task 4)
     */
    @Transactional
    public RecalcStats recalculateFarm(Long farmId, Instant from, Instant to) {
        List<Long> livestockIds = ranchQueryPort.findAllByFarmId(farmId).stream()
                .map(LivestockInfo::id)
                .toList();
        List<CapsuleBinding> bindings = deviceQueryPort.findActiveCapsuleBindings(livestockIds);
        if (bindings.isEmpty()) {
            return new RecalcStats(0, 0);
        }
        Map<Long, List<ExclusionWindow>> windowsByLivestock =
                rawFeverWindowsByFarm(farmId, scanFrom(from), scanTo(to));
        int rows = 0;
        for (CapsuleBinding binding : bindings) {
            rows += recalculate(binding.deviceId(), binding.livestockId(), from, to,
                    windowsByLivestock.getOrDefault(binding.livestockId(), List.of()));
        }
        return new RecalcStats(bindings.size(), rows);
    }

    /**
     * Outcome of one recalculation sweep: {@code devices} = active capsule
     * bindings processed, {@code events} = drinking-event rows written
     * (confirmed events + borderline candidates + §15.4 label restores).
     */
    public record RecalcStats(int devices, int events) {}

    /**
     * One device, one transaction: snapshot labels → delete → re-insert →
     * restore. {@code prefetchedWindows} carries the herd-batch windows from
     * {@link #recalculateFarm} (B4); when null they are resolved here.
     *
     * @return number of drinking-event rows written
     */
    private int recalculate(Long deviceId, Long livestockId, Instant from, Instant to,
                            List<ExclusionWindow> prefetchedWindows) {
        Params params = currentParams();
        Instant deleteFrom = from.minus(Duration.ofHours(params.recalcOverlapHours()));
        Instant deleteTo = to.plus(Duration.ofHours(params.recalcOverlapHours()));

        List<TemperatureLogJpaEntity> logs = temperatureLogJpaRepository
                .findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
                        deviceId, deleteFrom.minus(DAY_PREFIX), deleteTo.plus(recoveryLookahead(params)));
        List<TempPoint> rawPoints = logs.stream()
                .map(entity -> new TempPoint(entity.getRecordedAt(),
                        entity.getTemperature().doubleValue(), entity.getSource()))
                .toList();
        // The active installation is the owner; fall back to the point rows'
        // own livestock attribution when the capsule is no longer bound (a
        // removed device's history still recalculates against its old owner).
        if (livestockId == null) {
            livestockId = logs.stream()
                    .map(TemperatureLogJpaEntity::getLivestockId)
                    .filter(java.util.Objects::nonNull)
                    .findFirst()
                    .orElse(null);
        }
        List<ExclusionWindow> windows = prefetchedWindows != null
                ? prefetchedWindows
                : exclusionWindowsForDevice(deviceId, livestockId, from, to);
        DetectionResult result = detectRange(rawPoints, COW_DAY_ZONE, deleteFrom, deleteTo, windows, params);

        // §15.4 label snapshot: only algorithm rows carry restorable labels —
        // MANUAL rows are never deleted and skipped here.
        List<DrinkingEventJpaEntity> existing = drinkingEventJpaRepository
                .findByDeviceIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThan(deviceId, deleteFrom, deleteTo);
        Map<Instant, DrinkingEventLabel> labelByStart = new HashMap<>();
        List<DrinkingEventJpaEntity> labeledRows = new ArrayList<>();
        for (DrinkingEventJpaEntity row : existing) {
            if (DrinkingEventSources.MANUAL.equals(row.getSource()) || row.getLabel() == DrinkingEventLabel.UNLABELED) {
                continue;
            }
            labelByStart.put(row.getEventStartAt(), row.getLabel());
            labeledRows.add(row);
        }

        drinkingEventJpaRepository.deleteAlgorithmRowsInWindow(deviceId, deleteFrom, deleteTo);

        // Re-insert. Within one recalculation the UNIQUE key cannot collide:
        // valley starts are distinct inside a scan batch, restores skip starts
        // already produced, and MANUAL rows use a different algorithm_version.
        // The remaining race (two concurrent recalcs) is serialized by the T4
        // scheduler, so the "candidate collision → silent skip" contract is
        // honored structurally rather than via exception handling (a caught
        // constraint violation would poison the surrounding PostgreSQL tx).
        Set<Instant> insertedStarts = new HashSet<>();
        for (Valley event : result.events()) {
            insertRow(deviceId, livestockId, event, event.source(),
                    labelByStart.getOrDefault(event.startAt(), DrinkingEventLabel.UNLABELED), insertedStarts);
        }
        for (Valley candidate : result.candidates()) {
            insertRow(deviceId, livestockId, candidate, DrinkingEventSources.ALGORITHM_CANDIDATE,
                    labelByStart.getOrDefault(candidate.startAt(), DrinkingEventLabel.UNLABELED), insertedStarts);
        }
        // Human verdicts must survive even when the detector no longer finds
        // the valley (e.g. after a parameter change) — spec §15.4: labeled
        // rows that were not re-derived come back with their label intact.
        int restores = 0;
        for (DrinkingEventJpaEntity row : labeledRows) {
            if (!insertedStarts.contains(row.getEventStartAt())) {
                insertRestored(row);
                restores++;
            }
        }
        int rowsWritten = result.events().size() + result.candidates().size() + restores;
        log.debug("Drinking recalc device={} window=[{},{}): {} events, {} candidates, {} labeled restores",
                deviceId, deleteFrom, deleteTo, result.events().size(), result.candidates().size(), restores);
        return rowsWritten;
    }

    private void insertRow(Long deviceId, Long livestockId, Valley valley, String source,
                           DrinkingEventLabel label, Set<Instant> insertedStarts) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setDeviceId(deviceId);
        entity.setLivestockId(livestockId);
        entity.setEventStartAt(valley.startAt());
        entity.setEventEndAt(valley.troughAt());
        entity.setTempDrop(scale(valley.tempDrop(), 2));
        entity.setMinTemp(scale(valley.minTemp(), 2));
        entity.setSource(source);
        entity.setLabel(label);
        entity.setConfidence(scale(valley.confidence(), 3));
        entity.setAlgorithmVersion(DrinkingAlgorithmVersion.V1);
        drinkingEventJpaRepository.save(entity);
        insertedStarts.add(valley.startAt());
    }

    /** Re-insert a snapshot row that the new scan did not re-derive. */
    private void insertRestored(DrinkingEventJpaEntity row) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setDeviceId(row.getDeviceId());
        entity.setLivestockId(row.getLivestockId());
        entity.setEventStartAt(row.getEventStartAt());
        entity.setEventEndAt(row.getEventEndAt());
        entity.setTempDrop(row.getTempDrop());
        entity.setMinTemp(row.getMinTemp());
        entity.setSource(row.getSource());
        entity.setLabel(row.getLabel());
        entity.setConfidence(row.getConfidence());
        entity.setAlgorithmVersion(row.getAlgorithmVersion());
        entity.setNote(row.getNote());
        drinkingEventJpaRepository.save(entity);
    }

    private static BigDecimal scale(double value, int scale) {
        return BigDecimal.valueOf(value).setScale(scale, RoundingMode.HALF_UP);
    }

    private Duration recoveryLookahead(Params params) {
        return Duration.ofMinutes(params.recoveryWindowMin());
    }

    private Instant scanFrom(Instant from) {
        return from.minus(Duration.ofHours(recalcOverlapHours)).minus(DAY_PREFIX);
    }

    private Instant scanTo(Instant to) {
        // Symmetric with scanFrom: the same configurable overlap, so tuning
        // health.drinking.recalc-overlap-hours keeps both window bounds in
        // one piece (m-a) instead of skewing the right edge by a hard 1h.
        return to.plus(Duration.ofHours(recalcOverlapHours)).plus(recoveryLookahead(currentParams()));
    }

    // ── Exclusion window assembly ────────────────────────────────

    private List<ExclusionWindow> exclusionWindowsForDevice(Long deviceId, Long livestockId,
                                                            Instant from, Instant to) {
        if (livestockId == null) {
            log.warn("Drinking recalc of device {} has no livestock binding — physiology exclusion windows skipped", deviceId);
            return List.of();
        }
        // Raw (unbuffered) windows — the kernel applies the fever buffer.
        return rawFeverWindowsForLivestock(livestockId, scanFrom(from), scanTo(to));
    }

    private static List<ExclusionWindow> toExclusionWindows(List<PhysiologyWindow> physiologyWindows) {
        return physiologyWindows.stream()
                .map(w -> new ExclusionWindow(w.occurredAt(), w.endedAt()))
                .toList();
    }

    /**
     * TEMPERATURE_ABNORMAL alert windows per livestock: ACTIVE alerts are
     * open-ended [created_at, ∞); AUTO_RESOLVED/DISMISSED alerts close at
     * resolved_at. The fever buffer is applied later, inside the kernel.
     */
    private Map<Long, List<ExclusionWindow>> alertWindowsByLivestock(Long farmId, Instant since) {
        Map<Long, List<ExclusionWindow>> byLivestock = new HashMap<>();
        ranchQueryPort.findActiveAlertsByFarmIdAndTypes(farmId, FEVER_ALERT_TYPES)
                .forEach(alert -> byLivestock
                        .computeIfAbsent(alert.livestockId(), ignored -> new ArrayList<>())
                        .add(new ExclusionWindow(alert.createdAt(), alert.resolvedAt())));
        ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(farmId, FEVER_ALERT_TYPES, since)
                .forEach(alert -> byLivestock
                        .computeIfAbsent(alert.livestockId(), ignored -> new ArrayList<>())
                        .add(new ExclusionWindow(alert.createdAt(), alert.resolvedAt())));
        return byLivestock;
    }

    /**
     * Raw (unbuffered) fever window assembly per livestock of a farm over
     * {@code [from, to)}: physiology illness windows (batch, B4) ∪
     * TEMPERATURE_ABNORMAL alert windows. Shared by the detector's
     * per-farm/device recalculations and the Task 5 statistics — one
     * assembly, so detection and day-coverage math cannot drift.
     */
    private Map<Long, List<ExclusionWindow>> rawFeverWindowsByFarm(Long farmId, Instant from, Instant to) {
        Map<Long, List<ExclusionWindow>> byLivestock = new HashMap<>();
        physiologyQueryPort.activeWindowsForFarm(farmId, from, to)
                .forEach((livestockId, windows) ->
                        // Mutable copy: the alert merge below may addAll into
                        // this value when a livestock has both sources (e.g. an
                        // active disposition AND a resolved fever alert).
                        byLivestock.put(livestockId, new ArrayList<>(toExclusionWindows(windows))));
        alertWindowsByLivestock(farmId, from.minus(Duration.ofHours(feverBufferHours)))
                .forEach((livestockId, windows) -> byLivestock
                        .computeIfAbsent(livestockId, ignored -> new ArrayList<>())
                        .addAll(windows));
        return byLivestock;
    }

    /**
     * Raw windows of one livestock — the single-livestock view of
     * {@link #rawFeverWindowsByFarm}, resolving the farm from the livestock.
     */
    private List<ExclusionWindow> rawFeverWindowsForLivestock(Long livestockId, Instant from, Instant to) {
        Long farmId = ranchQueryPort.findLivestockById(livestockId)
                .map(LivestockInfo::farmId)
                .orElse(null);
        if (farmId == null) {
            log.warn("Fever windows of livestock {} could not resolve a farm — alert exclusion windows skipped", livestockId);
            return List.of();
        }
        return rawFeverWindowsByFarm(farmId, from, to).getOrDefault(livestockId, List.of());
    }

    /**
     * Buffered fever windows of one livestock over {@code [from, to)}
     * (package-visible, NIX-256 Task 5a): physiology illness windows ∪
     * TEMPERATURE_ABNORMAL alert windows with the defervescence buffer
     * applied — exactly the exclusion semantics the detector uses inside
     * {@code detectRange}. Consumers computing per-day fever coverage
     * (baseline sample-day rule, F4) read this so statistics and detection
     * share one source of truth.
     */
    List<ExclusionWindow> feverWindowsForLivestock(Long livestockId, Instant from, Instant to) {
        return extendWindows(rawFeverWindowsForLivestock(livestockId, from, to), feverBufferHours);
    }

    /**
     * Buffered fever windows of a whole farm, keyed by livestock id
     * (package-visible, NIX-256 Task 5a) — the batch variant of
     * {@link #feverWindowsForLivestock} for herd-level statistics (peer
     * comparison) that must not re-query the farm per head.
     */
    Map<Long, List<ExclusionWindow>> feverWindowsByFarm(Long farmId, Instant from, Instant to) {
        Map<Long, List<ExclusionWindow>> buffered = new HashMap<>();
        rawFeverWindowsByFarm(farmId, from, to)
                .forEach((livestockId, windows) ->
                        buffered.put(livestockId, extendWindows(windows, feverBufferHours)));
        return buffered;
    }
}
