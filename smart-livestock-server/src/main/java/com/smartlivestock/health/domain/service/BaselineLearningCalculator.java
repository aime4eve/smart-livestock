package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Pure learning kernel for the individual temperature baseline
 * (plan 2026-11-03 Task 2). Runs the admission pipeline and the weighted
 * statistics over one livestock's window; no Spring wiring, no repository
 * access, fully deterministic — identical inputs give identical outputs
 * regardless of the order of elements inside the input lists.
 *
 * <p>Pipeline (first matching reason wins per sample):</p>
 * <ol>
 *   <li>event-time window trim {@code [asOf - windowDays, asOf)} (silent);</li>
 *   <li>source whitelist;</li>
 *   <li>physiological plausibility 35.0-43.0 °C;</li>
 *   <li>logical dedup on (deviceId, recordedAt, source);</li>
 *   <li>merged exclusion windows: illness (+fever buffer), drinking
 *       (+recovery window), fever alerts (LEARNED previous source only,
 *       +fever buffer — DEFAULT cold start is never vetoed by its own
 *       default-baseline alerts);</li>
 *   <li>quiet-state screening via activity join or night fallback;</li>
 *   <li>robust median/MAD outlier filter;</li>
 *   <li>farm-local day grouping and day qualification;</li>
 *   <li>per-day equal weights, weighted mean and ±2σ band.</li>
 * </ol>
 */
@Service
public class BaselineLearningCalculator {

    private static final BigDecimal MIN_PLAUSIBLE_TEMP = new BigDecimal("35.0");
    private static final BigDecimal MAX_PLAUSIBLE_TEMP = new BigDecimal("43.0");
    private static final int NIGHT_START_HOUR = 21;
    private static final int NIGHT_END_HOUR = 6;
    private static final String SOURCE_DEFAULT = "DEFAULT";
    private static final String SOURCE_LEARNED = "LEARNED";
    /** Working precision for divisions and the variance square root. */
    private static final MathContext MC = MathContext.DECIMAL64;

    /**
     * Canonical processing order for temperature samples. Candidates are
     * sorted by (recordedAt, temperature, deviceId, source, id) before the
     * pipeline runs, so duplicate resolution ("keep first occurrence") and
     * exclusion ordering do not depend on the caller's input order.
     */
    private static final Comparator<TemperatureLog> CANONICAL_ORDER =
            Comparator.comparing(TemperatureLog::getRecordedAt)
                    .thenComparing(TemperatureLog::getTemperature,
                            Comparator.nullsFirst(Comparator.<BigDecimal>naturalOrder()))
                    .thenComparing(TemperatureLog::getDeviceId,
                            Comparator.nullsFirst(Comparator.<Long>naturalOrder()))
                    .thenComparing(TemperatureLog::getSource,
                            Comparator.nullsFirst(Comparator.<String>naturalOrder()))
                    .thenComparing(TemperatureLog::getId,
                            Comparator.nullsFirst(Comparator.<Long>naturalOrder()));

    /** Logical dedup key per plan §1.1: (device_id, recorded_at, source). */
    private record DedupKey(Long deviceId, Instant recordedAt, String source) {
    }

    public BaselineLearningResult calculate(BaselineLearningInput input) {
        Instant windowStartBoundary = input.asOf().minus(Duration.ofDays(input.windowDays()));
        List<BaselineLearningResult.ExcludedSample> excluded = new ArrayList<>();

        // a) Event-time trim: keep recordedAt in [asOf - windowDays, asOf).
        // Out-of-window and null-timestamp rows are dropped silently (no reason).
        List<TemperatureLog> trimmed = new ArrayList<>();
        for (TemperatureLog t : input.temperatures()) {
            Instant at = t.getRecordedAt();
            if (at == null || at.isBefore(windowStartBoundary) || !at.isBefore(input.asOf())) {
                continue;
            }
            trimmed.add(t);
        }
        trimmed.sort(CANONICAL_ORDER);

        // b) Source whitelist (DATAGEN/UNKNOWN are not on it by default).
        List<TemperatureLog> bySource = new ArrayList<>();
        for (TemperatureLog t : trimmed) {
            if (t.getSource() != null && input.allowedSources().contains(t.getSource())) {
                bySource.add(t);
            } else {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        t.getRecordedAt(), t.getTemperature(), BaselineAdmissionReason.SOURCE_NOT_ALLOWED));
            }
        }

        // c) Physiological plausibility 35.0 <= temp <= 43.0.
        List<TemperatureLog> plausible = new ArrayList<>();
        for (TemperatureLog t : bySource) {
            BigDecimal v = t.getTemperature();
            if (v == null || v.compareTo(MIN_PLAUSIBLE_TEMP) < 0 || v.compareTo(MAX_PLAUSIBLE_TEMP) > 0) {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        t.getRecordedAt(), v, BaselineAdmissionReason.IMPLAUSIBLE));
            } else {
                plausible.add(t);
            }
        }

        // d) Logical dedup; canonical order makes "first occurrence" deterministic.
        List<TemperatureLog> deduped = new ArrayList<>();
        Set<DedupKey> seen = new HashSet<>();
        for (TemperatureLog t : plausible) {
            if (seen.add(new DedupKey(t.getDeviceId(), t.getRecordedAt(), t.getSource()))) {
                deduped.add(t);
            } else {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        t.getRecordedAt(), t.getTemperature(), BaselineAdmissionReason.DUPLICATE));
            }
        }

        // e) Merged exclusion windows (buffer applied before merging).
        List<BaselineExclusionWindow> illness = extendAndMerge(
                input.illnessWindows(), Duration.ofHours(input.feverBufferHours()));
        List<BaselineExclusionWindow> drinking = extendAndMerge(
                input.drinkingWindows(), Duration.ofMinutes(input.drinkingRecoveryWindowMin()));
        boolean learnedBefore = SOURCE_LEARNED.equals(input.previousSource());
        // Cold start rule: alerts produced under the DEFAULT baseline never veto admission.
        List<BaselineExclusionWindow> feverAlerts = learnedBefore
                ? extendAndMerge(input.feverAlertWindows(), Duration.ofHours(input.feverBufferHours()))
                : List.of();

        List<TemperatureLog> windowSurvivors = new ArrayList<>();
        BigDecimal frozenBaseline = learnedBefore ? input.previousBaselineTemp() : null;
        for (TemperatureLog t : deduped) {
            Instant at = t.getRecordedAt();
            if (covers(illness, at)) {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        at, t.getTemperature(), BaselineAdmissionReason.ILLNESS_WINDOW));
            } else if (covers(drinking, at)) {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        at, t.getTemperature(), BaselineAdmissionReason.DRINKING_WINDOW));
            } else if (covers(feverAlerts, at)) {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        at, t.getTemperature(), BaselineAdmissionReason.FEVER_ALERT_WINDOW));
            } else if (frozenBaseline != null && t.getTemperature() != null
                    && t.getTemperature().subtract(frozenBaseline)
                            .compareTo(BigDecimal.ONE) >= 0) {
                // LEARNED re-learning per plan §1.2.3: the sample itself reads
                // ≥1.0°C (ELEVATED threshold semantics) over the frozen
                // pre-learning baseline — catches spikes whose alert ticket
                // was created after the sample (recorded_at < created_at) and
                // backfilled batches. DEFAULT cold start is exempt by design.
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        at, t.getTemperature(), BaselineAdmissionReason.FEVER_ELEVATED));
            } else {
                windowSurvivors.add(t);
            }
        }

        // f) Quiet-state screening. Activity mode is enabled only when the
        // window contains at least one activity row with a non-null index.
        List<ActivityLog> windowActivities = new ArrayList<>();
        for (ActivityLog a : input.activities()) {
            Instant at = a.getRecordedAt();
            if (a.getActivityIndex() != null && at != null
                    && !at.isBefore(windowStartBoundary) && at.isBefore(input.asOf())) {
                windowActivities.add(a);
            }
        }
        windowActivities.sort(Comparator.comparing(ActivityLog::getRecordedAt));
        boolean activityMode = !windowActivities.isEmpty();
        BigDecimal activityMedian = activityMode
                ? median(windowActivities.stream().map(ActivityLog::getActivityIndex).sorted().toList())
                : null;
        Duration tolerance = Duration.ofMinutes(input.activityToleranceMin());

        List<TemperatureLog> quiet = new ArrayList<>();
        for (TemperatureLog t : windowSurvivors) {
            Instant at = t.getRecordedAt();
            if (!activityMode) {
                // No usable activity data at all: night fallback keeps night samples only.
                if (isNight(at, input.farmZone())) {
                    quiet.add(t);
                } else {
                    excluded.add(new BaselineLearningResult.ExcludedSample(
                            at, t.getTemperature(), BaselineAdmissionReason.ACTIVE_PERIOD));
                }
                continue;
            }
            ActivityLog nearest = nearestWithin(at, windowActivities, tolerance);
            if (nearest != null) {
                if (nearest.getActivityIndex().compareTo(activityMedian) < 0) {
                    quiet.add(t);
                } else {
                    excluded.add(new BaselineLearningResult.ExcludedSample(
                            at, t.getTemperature(), BaselineAdmissionReason.ACTIVE_PERIOD));
                }
            } else if (isNight(at, input.farmZone())) {
                quiet.add(t);
            } else {
                excluded.add(new BaselineLearningResult.ExcludedSample(
                        at, t.getTemperature(), BaselineAdmissionReason.ACTIVITY_UNKNOWN));
            }
        }

        // g) Robust median/MAD filter with the mad floor so MAD=0 windows
        // never wipe out every sample.
        List<TemperatureLog> admitted = new ArrayList<>();
        if (!quiet.isEmpty()) {
            List<BigDecimal> temps = quiet.stream()
                    .map(TemperatureLog::getTemperature).sorted().toList();
            BigDecimal med = median(temps);
            List<BigDecimal> absDevs = quiet.stream()
                    .map(t -> t.getTemperature().subtract(med).abs()).sorted().toList();
            BigDecimal mad = median(absDevs);
            BigDecimal effectiveMad = mad.max(input.madFloor());
            BigDecimal threshold = BigDecimal.valueOf(3).multiply(effectiveMad);
            for (TemperatureLog t : quiet) {
                if (t.getTemperature().subtract(med).abs().compareTo(threshold) > 0) {
                    excluded.add(new BaselineLearningResult.ExcludedSample(
                            t.getRecordedAt(), t.getTemperature(), BaselineAdmissionReason.ROBUST_OUTLIER));
                } else {
                    admitted.add(t);
                }
            }
        }

        // h) Farm-local day grouping and day qualification.
        Map<LocalDate, List<TemperatureLog>> byDay = new TreeMap<>();
        for (TemperatureLog t : admitted) {
            byDay.computeIfAbsent(
                    t.getRecordedAt().atZone(input.farmZone()).toLocalDate(),
                    k -> new ArrayList<>()).add(t);
        }
        List<LocalDate> qualifiedDays = new ArrayList<>();
        for (Map.Entry<LocalDate, List<TemperatureLog>> entry : byDay.entrySet()) {
            if (entry.getValue().size() >= input.minSamplesPerDay()) {
                qualifiedDays.add(entry.getKey());
            }
        }
        Instant earliestQualifiedSample = null;
        for (LocalDate day : qualifiedDays) {
            for (TemperatureLog t : byDay.get(day)) {
                if (earliestQualifiedSample == null || t.getRecordedAt().isBefore(earliestQualifiedSample)) {
                    earliestQualifiedSample = t.getRecordedAt();
                }
            }
        }

        // i) Weighted statistics; each day carries weight 1 so dense backfill
        // days cannot outvote other days.
        if (!qualifiedDays.isEmpty() && qualifiedDays.size() >= input.minQualifiedDays()) {
            BigDecimal sumWeightedX = BigDecimal.ZERO;
            BigDecimal sumWeights = BigDecimal.ZERO;
            for (LocalDate day : qualifiedDays) {
                List<TemperatureLog> daySamples = byDay.get(day);
                BigDecimal w = BigDecimal.ONE.divide(BigDecimal.valueOf(daySamples.size()), MC);
                for (TemperatureLog t : daySamples) {
                    sumWeightedX = sumWeightedX.add(w.multiply(t.getTemperature()));
                    sumWeights = sumWeights.add(w);
                }
            }
            BigDecimal mean = sumWeightedX.divide(sumWeights, MC);
            BigDecimal variance = BigDecimal.ZERO;
            for (LocalDate day : qualifiedDays) {
                List<TemperatureLog> daySamples = byDay.get(day);
                BigDecimal w = BigDecimal.ONE.divide(BigDecimal.valueOf(daySamples.size()), MC);
                for (TemperatureLog t : daySamples) {
                    BigDecimal dev = t.getTemperature().subtract(mean);
                    variance = variance.add(w.multiply(dev).multiply(dev));
                }
            }
            variance = variance.divide(sumWeights, MC);
            BigDecimal sigma = variance.sqrt(MC);
            BigDecimal twoSigma = sigma.multiply(BigDecimal.valueOf(2));
            return new BaselineLearningResult(
                    SOURCE_LEARNED,
                    SOURCE_DEFAULT.equals(input.previousSource()),
                    false,
                    mean.setScale(2, RoundingMode.HALF_UP),
                    mean.subtract(twoSigma).setScale(2, RoundingMode.HALF_UP),
                    mean.add(twoSigma).setScale(2, RoundingMode.HALF_UP),
                    admitted.size(),
                    qualifiedDays.size(),
                    earliestQualifiedSample,
                    input.asOf(),
                    List.copyOf(excluded));
        }

        // j) Insufficient data: keep previous source/baseline, report real
        // evidence only (the caller decides whether to persist anything).
        return new BaselineLearningResult(
                input.previousSource(),
                false,
                true,
                input.previousBaselineTemp(),
                null,
                null,
                admitted.size(),
                qualifiedDays.size(),
                earliestQualifiedSample,
                input.asOf(),
                List.copyOf(excluded));
    }

    /**
     * Buffers every window end by {@code extension} (open windows stay open)
     * and merges overlapping or touching windows, mirroring the semantics of
     * {@code DrinkingSummaryService.mergeWindows} with an independent
     * implementation on {@link BaselineExclusionWindow}.
     */
    private static List<BaselineExclusionWindow> extendAndMerge(
            List<BaselineExclusionWindow> windows, Duration extension) {
        List<BaselineExclusionWindow> extended = new ArrayList<>();
        for (BaselineExclusionWindow w : windows) {
            if (w == null) {
                continue;
            }
            Instant end = w.end() == null ? null : w.end().plus(extension);
            extended.add(new BaselineExclusionWindow(w.start(), end));
        }
        extended.sort(Comparator.comparing(BaselineExclusionWindow::start));
        List<BaselineExclusionWindow> merged = new ArrayList<>();
        for (BaselineExclusionWindow w : extended) {
            BaselineExclusionWindow last = merged.isEmpty() ? null : merged.get(merged.size() - 1);
            if (last != null && (last.end() == null || !w.start().isAfter(last.end()))) {
                Instant newEnd = (last.end() == null || w.end() == null)
                        ? null
                        : (last.end().isAfter(w.end()) ? last.end() : w.end());
                merged.set(merged.size() - 1, new BaselineExclusionWindow(last.start(), newEnd));
            } else {
                merged.add(w);
            }
        }
        return List.copyOf(merged);
    }

    /** Half-open containment: start <= t < end, open end covers everything after start. */
    private static boolean covers(List<BaselineExclusionWindow> windows, Instant at) {
        for (BaselineExclusionWindow w : windows) {
            boolean afterStart = !at.isBefore(w.start());
            boolean beforeEnd = w.end() == null || at.isBefore(w.end());
            if (afterStart && beforeEnd) {
                return true;
            }
        }
        return false;
    }

    /** Night per plan §1.2: farm-local hour >= 21 or < 6. */
    private static boolean isNight(Instant at, ZoneId zone) {
        int hour = at.atZone(zone).getHour();
        return hour >= NIGHT_START_HOUR || hour < NIGHT_END_HOUR;
    }

    /**
     * Nearest activity row with non-null index within ±tolerance. Ties are
     * resolved to the earliest row; {@code activities} must be sorted by
     * recordedAt so the result is deterministic.
     */
    private static ActivityLog nearestWithin(Instant at, List<ActivityLog> activities, Duration tolerance) {
        ActivityLog best = null;
        Duration bestGap = null;
        for (ActivityLog a : activities) {
            Duration gap = Duration.between(at, a.getRecordedAt()).abs();
            if (gap.compareTo(tolerance) > 0) {
                continue;
            }
            if (best == null || gap.compareTo(bestGap) < 0) {
                best = a;
                bestGap = gap;
            }
        }
        return best;
    }

    /**
     * Median of a non-empty list; for an even size the two middle values are
     * averaged (division by 2 always terminates in decimal).
     */
    private static BigDecimal median(List<BigDecimal> sortedValues) {
        int n = sortedValues.size();
        int mid = n / 2;
        if (n % 2 == 1) {
            return sortedValues.get(mid);
        }
        return sortedValues.get(mid - 1).add(sortedValues.get(mid))
                .divide(BigDecimal.valueOf(2));
    }
}
