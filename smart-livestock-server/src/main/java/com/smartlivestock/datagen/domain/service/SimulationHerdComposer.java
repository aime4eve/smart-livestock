package com.smartlivestock.datagen.domain.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Deterministic, literature-parameterized herd simulator (plan 2026-11-05,
 * Task 2). Pure computation: no Spring, no IO, no clock — {@code asOf} is
 * passed in by the caller so the same seed always replays the same herd.
 *
 * <p>Generation model per animal i (parameter sources keyed to
 * docs/research/2026-11-05-牛群仿真参数文献取证.md, marked P# inline):
 * <pre>
 * RRT(t) = μᵢ                                        (P1, truncated normal)
 *        + amplitude·cos(2π(t − 23.5h)/24h)           (P3/P4, night peak)
 *        + milking twin bells @07:00/19:00            (P5, retro-derived)
 *        + AR(1) noise (φ=0.6, SD=0.4)                (P2)
 *        + Σ drinking valleys                         (P7)
 *        + THI offset (fixed THI=70 → +0.1)           (P14, simplified)
 *        + event modulation                           (P9/P11/P16)
 * </pre>
 *
 * <p>Determinism contract: one master RNG {@code new Random(seed)} decides the
 * event-class quota assignment; each animal generates from its own derived
 * stream {@code new Random(seed + index)} with a fixed draw order (μᵢ → event
 * schedule → water bouts per day → per-point innovations), so two calls with
 * equal params/asOf produce identical series.
 */
public final class SimulationHerdComposer {

    /**
     * Default farm wall-clock zone for every day-phase calculation (P3/P4
     * night peak, activity envelope, drinking bouts, milking bells anchor to
     * the LOCAL clock per the literature). Asia/Shanghai has no DST, so
     * hour-of-day math stays deterministic. Overridable per run via
     * {@link SimulationHerdParams#farmZoneId()}.
     */
    public static final String DEFAULT_FARM_ZONE_ID = "Asia/Shanghai";

    /** ZoneId view of {@link #DEFAULT_FARM_ZONE_ID} (kept for tests). */
    public static final ZoneId SIMULATION_ZONE = ZoneId.of(DEFAULT_FARM_ZONE_ID);

    /** P14 simplification: the simulated period is assumed to sit at a constant
     *  THI of 70 (moderate load), so the THI term collapses to a fixed
     *  +thiSlope·(70−65) = +0.1 ℃ offset instead of an hourly covariate. */
    private static final double THI_SIMULATED = 70.0;

    /** P5 retro-derived: twin bells aligned to milking times, each bell half
     *  the total artifact amplitude, Gaussian with FWHM ≈ 1h (σ=25 min). */
    private static final double MILKING_BELL_SIGMA_MINUTES = 25.0;
    private static final double MILKING_BELL_CUTOFF_MINUTES = 90.0;
    private static final double[] MILKING_BELL_HOURS = {7.0, 19.0};

    /** P7 water-valley shape: 2 descending grid points, 1 valley point, then
     *  exponential recovery. Contribution beyond 6τ is < 0.3% of depth. */
    private static final double VALLEY_TAIL_TAUS = 6.0;

    public SimulationHerdComposer() {
    }

    // ------------------------------------------------------------------
    // Input / output contracts
    // ------------------------------------------------------------------

    /**
     * Generation parameters. Literature values carry defaults via
     * {@link #defaults(List, List, int, int, long)}; every field is overridable
     * for what-if experiments. Each constant is annotated with its P# source.
     */
    public record SimulationHerdParams(
            List<Long> livestockIds,
            List<Long> deviceIds,
            int days,
            int granularityMinutes,
            long seed,
            /* P1 */ double baselineMean,
            /* P1 */ double baselineSd,
            /* P1 */ double baselineTruncLow,
            /* P1 */ double baselineTruncHigh,
            /* P2 */ double noiseSd,
            /* P2 */ double arPhi,
            /* P3 */ double diurnalAmplitude,
            /* P4 */ double diurnalPeakHour,
            /* P5 retro */ double milkingArtifactAmplitude,
            /* P7 */ double waterBoutPerDayMean,
            /* P7 */ double waterDepthLow,
            /* P7 */ double waterDepthHigh,
            /* P7 */ double waterRecoveryMinutes,
            /* P8 */ double estrusHeadRatio,
            /* P8 */ double estrusActivityMultiplier,
            /* P9 */ double estrusRrtRise,
            /* P8 */ int estrusDurationLowHours,
            /* P8 */ int estrusDurationHighHours,
            /* P11 */ double prepartumHeadRatio,
            /* P11 */ double prepartumRrtDrop,
            /* P11 */ int prepartumDropWindowHours,
            /* P13 */ int prepartumActivityRiseHours,
            /* P13 */ double prepartumActivityMultiplier,
            /* P16 */ double feverHeadRatio,
            /* P16 */ double feverDelta,
            /* P16 */ int feverDurationHours,
            /* retro */ double detachedHeadRatio,
            /* P14 */ double thiSlope,
            /* P14 */ double thiOnset,
            double activityDayLow,
            double activityDayHigh,
            double activityNightLow,
            double activityNightHigh,
            /* farm wall clock for every day-phase calc (P3/P4/P5/P7 anchors) */
            String farmZoneId) {

        public SimulationHerdParams {
            livestockIds = List.copyOf(livestockIds);
            deviceIds = List.copyOf(deviceIds);
            farmZoneId = farmZoneId == null || farmZoneId.isBlank()
                    ? DEFAULT_FARM_ZONE_ID : farmZoneId;
        }

        /** Literature-default parameter set (values from the research doc). */
        public static SimulationHerdParams defaults(List<Long> livestockIds, List<Long> deviceIds,
                                                    int days, int granularityMinutes, long seed) {
            return defaults(livestockIds, deviceIds, days, granularityMinutes, seed,
                    DEFAULT_FARM_ZONE_ID);
        }

        /** Literature defaults with an explicit farm wall-clock zone. */
        public static SimulationHerdParams defaults(List<Long> livestockIds, List<Long> deviceIds,
                                                    int days, int granularityMinutes, long seed,
                                                    String farmZoneId) {
            return new SimulationHerdParams(
                    livestockIds, deviceIds, days, granularityMinutes, seed,
                    39.0, 0.4, 38.6, 39.5,   // P1: μᵢ ~ N(39.0, 0.4) truncated [38.6, 39.5]
                    0.4, 0.6,                // P2: in-animal noise SD 0.4, AR(1) φ=0.6
                    0.4, 23.5,               // P3 amplitude 0.4 / P4 peak phase 23:30
                    0.2,                     // P5 retro: milking twin-bell amplitude
                    10.0, 2.3, 4.9, 58,      // P7: ~10 bouts/day, depth 2.3–4.9, recovery mean 58 min
                    0.20, 3.0, 0.55, 8, 30,  // P8: 20% heads, ×3 activity, 8–30h / P9: RRT +0.55
                    0.10, 0.3, 36, 8, 1.5,   // P11: 10% heads, −0.3 over 36h / P13: last 8h activity ×1.5
                    0.10, 0.8, 18,           // P16: 10% heads, +0.8, ~18h (plan: 12–24h)
                    0.10,                    // retro: detached-sensor head ratio
                    0.02, 65,                // P14: slope 0.02 ℃/THI above onset 65
                    30, 90, 5, 25,           // activity envelope: day U(30,90) / night U(5,25)
                    farmZoneId);             // day phases anchor to the farm wall clock
        }
    }

    /** Main event class per animal (mirrors simulation_truth_baselines.herd_class).
     *  WATER is reserved in the DB check constraint but never assigned here. */
    public enum HerdClass { CLEAN, WATER, FEVER, ESTRUS, PREPARTUM, DETACHED }

    /** One telemetry point. Activity triple is null while the sensor is
     *  detached (no activity row is written for that point). */
    public record SeriesPoint(
            Instant recordedAt,
            BigDecimal temperature,
            Integer activityIndex,
            Integer stepCount,
            Double distanceMeters) {
    }

    /** Ground-truth label window (type maps to ground_truth_labels.pattern). */
    public record LabelWindow(Long livestockId, ScenarioTypeRef type, Instant start, Instant end) {

        /** Local string mirror of the label types the composer emits — keeps
         *  the domain service free of datagen model imports. */
        public enum ScenarioTypeRef { ESTRUS, PREPARTUM, ILLNESS, DETACHED }
    }

    /**
     * P7 drinking-bout truth metadata (evaluation/test anchor), carrying the
     * full shape the simulated drinking detector emits an event row for:
     * {@code descentStartAt} (descent onset = drinking start, the composer's
     * fixed 2-grid-point descent before the bottom), {@code valleyTime} (the
     * trough = drinking end), {@code depth} (start − trough), the recovery
     * tau and {@code minTemp} — the lowest sampled temperature around the
     * trough, i.e. what a real detector would read off the telemetry series.
     */
    public record WaterBout(Instant descentStartAt, Instant valleyTime, double depth,
                            double recoveryTauMinutes, BigDecimal minTemp) {

        /**
         * Scheduling convenience: bouts leave the scheduler without detector
         * metadata ({@code descentStartAt}/{@code minTemp} null) —
         * {@code withDetectorMetadata} fills both once the points exist.
         */
        public WaterBout(Instant valleyTime, double depth, double recoveryTauMinutes) {
            this(null, valleyTime, depth, recoveryTauMinutes, null);
        }
    }

    /** Per-animal composed output. */
    public record HerdAnimal(
            Long livestockId,
            HerdClass herdClass,
            BigDecimal truthBaseline,
            List<SeriesPoint> points,
            List<LabelWindow> labels,
            List<WaterBout> waterBouts) {
    }

    /** Whole-herd composed output over the fixed window [windowStart, windowEnd). */
    public record SimulationHerdSeries(
            Instant windowStart,
            Instant windowEnd,
            int granularityMinutes,
            List<HerdAnimal> animals) {
    }

    // ------------------------------------------------------------------
    // Composition
    // ------------------------------------------------------------------

    public SimulationHerdSeries compose(SimulationHerdParams params, Instant asOf) {
        int herdSize = params.livestockIds().size();
        Instant windowStart = asOf.minus(Duration.ofDays(params.days()));
        HerdClass[] classes = allocateClasses(params, herdSize);

        List<HerdAnimal> animals = new ArrayList<>(herdSize);
        for (int i = 0; i < herdSize; i++) {
            animals.add(composeAnimal(params, i, classes[i], windowStart));
        }
        return new SimulationHerdSeries(windowStart, asOf, params.granularityMinutes(), animals);
    }

    /**
     * Event-class quota allocation: head counts equal round(ratio × herdSize)
     * exactly (test 9), with the assignment of quotas to heads shuffled by the
     * master seed. One head belongs to at most one main event class; the rest
     * stay CLEAN. WATER is never assigned (kept for the DB check constraint).
     */
    private HerdClass[] allocateClasses(SimulationHerdParams params, int herdSize) {
        int nEstrus = (int) Math.round(params.estrusHeadRatio() * herdSize);
        int nPrepartum = (int) Math.round(params.prepartumHeadRatio() * herdSize);
        int nFever = (int) Math.round(params.feverHeadRatio() * herdSize);
        int nDetached = (int) Math.round(params.detachedHeadRatio() * herdSize);

        HerdClass[] classes = new HerdClass[herdSize];
        List<Integer> heads = new ArrayList<>(herdSize);
        for (int i = 0; i < herdSize; i++) {
            classes[i] = HerdClass.CLEAN;
            heads.add(i);
        }
        // Master stream — deliberately separate from per-animal streams.
        Random master = new Random(params.seed());
        java.util.Collections.shuffle(heads, master);

        int cursor = 0;
        cursor = assign(classes, heads, cursor, nEstrus, HerdClass.ESTRUS);
        cursor = assign(classes, heads, cursor, nPrepartum, HerdClass.PREPARTUM);
        cursor = assign(classes, heads, cursor, nFever, HerdClass.FEVER);
        assign(classes, heads, cursor, nDetached, HerdClass.DETACHED);
        return classes;
    }

    private int assign(HerdClass[] classes, List<Integer> heads, int cursor,
                       int count, HerdClass clazz) {
        for (int k = 0; k < count && cursor < heads.size(); k++, cursor++) {
            classes[heads.get(cursor)] = clazz;
        }
        return cursor;
    }

    private HerdAnimal composeAnimal(SimulationHerdParams params, int index,
                                     HerdClass herdClass, Instant windowStart) {
        Random rng = new Random(params.seed() + index);
        long livestockId = params.livestockIds().get(index);

        // Every day-phase calc (circadian phase, day/night envelope, milking
        // bells) anchors to the FARM wall clock — the literature values
        // (P3/P4 night peak 23:30, day activity envelope, milking times) are
        // local-clock statements, never UTC ones.
        ZoneId zone = ZoneId.of(params.farmZoneId());

        // P1: μᵢ ~ N(mean, sd) truncated to [low, high] via rejection sampling.
        double mu = drawTruncatedBaseline(params, rng);

        EventSchedule event = drawEventSchedule(params, rng, herdClass, windowStart);
        List<WaterBout> bouts = scheduleWaterBouts(params, rng, windowStart);
        double[] valley = valleyContributions(params, bouts, windowStart);

        int granularity = params.granularityMinutes();
        int pointsPerDay = 24 * 60 / granularity;
        int totalPoints = params.days() * pointsPerDay;

        List<SeriesPoint> points = new ArrayList<>(totalPoints);
        double arNoise = noiseSdStationary(params) * rng.nextGaussian(); // stationary init
        double thiOffset = params.thiSlope() * (THI_SIMULATED - params.thiOnset()); // P14 simplified

        for (int k = 0; k < totalPoints; k++) {
            Instant t = windowStart.plus(Duration.ofMinutes((long) granularity * k));
            ZonedDateTime zoned = t.atZone(zone);
            double fracHour = zoned.getHour() + zoned.getMinute() / 60.0
                    + zoned.getSecond() / 3600.0;

            // P2: AR(1) innovation scaled for stationary SD = noiseSd.
            arNoise = params.arPhi() * arNoise
                    + Math.sqrt(1 - params.arPhi() * params.arPhi())
                    * params.noiseSd() * rng.nextGaussian();

            if (event.detachedDay != null && !t.isBefore(event.detachedDay)
                    && t.isBefore(event.detachedDay.plus(Duration.ofHours(24)))) {
                // Detached sensor: environmental-temperature swing (retro-derived,
                // 25–35 ℃ per plan/research, far below the 35–43 ingestion gate
                // at trough and grazing it at peak), no activity rows at all.
                double env = 30.0 + 5.0 * Math.sin(2 * Math.PI * (fracHour - 14.0) / 24.0);
                points.add(new SeriesPoint(t, round2(env), null, null, null));
                continue;
            }

            // P3/P4: circadian cosine, peak at diurnalPeakHour (23.5 → night peak).
            double diurnal = params.diurnalAmplitude()
                    * Math.cos(2 * Math.PI * (fracHour - params.diurnalPeakHour()) / 24.0);
            double milking = milkingArtifact(params, t, zoned); // P5 retro

            double rrt = mu + diurnal + milking + thiOffset + arNoise + valley[k]
                    + event.temperatureDelta(t, params);
            double activityMultiplier = event.activityMultiplier(t, params);

            boolean dayTime = zoned.getHour() >= 6 && zoned.getHour() <= 20;
            double base = dayTime
                    ? params.activityDayLow() + rng.nextDouble()
                            * (params.activityDayHigh() - params.activityDayLow())
                    : params.activityNightLow() + rng.nextDouble()
                            * (params.activityNightHigh() - params.activityNightLow());

            int activityIndex = (int) Math.round(base * activityMultiplier);
            // Step count derived from activity intensity (simulation-only channel):
            // day ×3.5 / night ×2, distance = steps × 0.5 m (retro-derived stride).
            int stepCount = dayTime
                    ? (int) Math.round(activityIndex * 3.5)
                    : (int) Math.round(activityIndex * 2.0);
            double distance = stepCount * 0.5;

            points.add(new SeriesPoint(t, round2(rrt), activityIndex, stepCount, distance));
        }

        List<LabelWindow> labels = new ArrayList<>(1);
        if (event.label != null) {
            labels.add(new LabelWindow(livestockId, event.label, event.labelStart, event.labelEnd));
        }

        // Detector metadata is filled AFTER the points exist: minTemp is the
        // lowest sampled temperature around the trough — exactly what a real
        // drinking detector reads off the telemetry series (F≈0.93 output).
        List<WaterBout> detectorBouts = withDetectorMetadata(params, bouts, windowStart, points);

        return new HerdAnimal(livestockId, herdClass, round2(mu), points, labels, detectorBouts);
    }

    /**
     * Enriches the scheduled bouts with the two fields the IO layer needs to
     * emit drinking_events rows: {@code descentStartAt} (the composer's fixed
     * 2-grid-point descent before the bottom) and {@code minTemp} (the lower
     * of the two grid samples bracketing the trough — the observable trough
     * value). Deterministic: pure function of the already-generated points.
     */
    private List<WaterBout> withDetectorMetadata(SimulationHerdParams params, List<WaterBout> bouts,
                                                 Instant windowStart, List<SeriesPoint> points) {
        if (bouts.isEmpty()) {
            return bouts;
        }
        long stepMillis = params.granularityMinutes() * 60_000L;
        long descentMillis = 2L * params.granularityMinutes() * 60_000L;
        List<WaterBout> enriched = new ArrayList<>(bouts.size());
        for (WaterBout bout : bouts) {
            int floorIndex = (int) Math.min(points.size() - 1L,
                    Math.max(0L, Duration.between(windowStart, bout.valleyTime()).toMillis() / stepMillis));
            BigDecimal minTemp = points.get(floorIndex).temperature();
            int ceilIndex = floorIndex + 1;
            if (ceilIndex < points.size()) {
                BigDecimal ceilTemp = points.get(ceilIndex).temperature();
                if (ceilTemp.compareTo(minTemp) < 0) {
                    minTemp = ceilTemp;
                }
            }
            enriched.add(new WaterBout(bout.valleyTime().minusMillis(descentMillis),
                    bout.valleyTime(), bout.depth(), bout.recoveryTauMinutes(), minTemp));
        }
        return enriched;
    }

    /** P1 truncated-normal rejection sampling for the true baseline μᵢ. */
    private double drawTruncatedBaseline(SimulationHerdParams params, Random rng) {
        for (int attempt = 0; attempt < 1000; attempt++) {
            double v = params.baselineMean() + params.baselineSd() * rng.nextGaussian();
            if (v >= params.baselineTruncLow() && v <= params.baselineTruncHigh()) {
                return v;
            }
        }
        return Math.max(params.baselineTruncLow(),
                Math.min(params.baselineTruncHigh(), params.baselineMean()));
    }

    private double noiseSdStationary(SimulationHerdParams params) {
        return params.noiseSd();
    }

    // ------------------------------------------------------------------
    // Event schedules
    // ------------------------------------------------------------------

    private static final class EventSchedule {
        HerdClass clazz;
        LabelWindow.ScenarioTypeRef label;
        Instant labelStart;
        Instant labelEnd;
        // ESTRUS
        Instant estrusStart;
        Duration estrusDuration;
        double estrusActivityMultiplier;
        // PREPARTUM
        Instant calving;
        // FEVER
        Instant feverStart;
        Instant feverEnd;
        // DETACHED
        Instant detachedDay;

        double temperatureDelta(Instant t, SimulationHerdParams p) {
            if (clazz == HerdClass.ESTRUS && estrusStart != null) {
                // P9: RRT rises toward +estrusRrtRise with the GRADUAL envelope.
                double progress = progress(t, estrusStart, estrusDuration);
                return p.estrusRrtRise() * gradualIntensity(progress);
            }
            if (clazz == HerdClass.PREPARTUM && calving != null) {
                // P11: linear decline to μᵢ − prepartumRrtDrop over the drop
                // window ending at calving; recovery after calving is implicit.
                Instant dropStart = calving.minus(Duration.ofHours(p.prepartumDropWindowHours()));
                if (!t.isBefore(dropStart) && t.isBefore(calving)) {
                    // NOTE: (double) cast required — toMillis()/toMillis() would
                    // be long integer division and always yield 0.
                    double progress = Duration.between(dropStart, t).toMillis()
                            / (double) Duration.ofHours(p.prepartumDropWindowHours()).toMillis();
                    return -p.prepartumRrtDrop() * progress;
                }
                return 0;
            }
            if (clazz == HerdClass.FEVER && feverStart != null) {
                // P16: +feverDelta over μᵢ, GRADUAL in / plateau / GRADUAL out.
                double progress = progress(t, feverStart, Duration.ofHours(p.feverDurationHours()));
                return p.feverDelta() * gradualIntensity(progress);
            }
            return 0;
        }

        double activityMultiplier(Instant t, SimulationHerdParams p) {
            if (clazz == HerdClass.ESTRUS && estrusStart != null) {
                // P8: activity × U(2.5,3.5) shaped by the same GRADUAL envelope
                // (drawn per event around estrusActivityMultiplier).
                double progress = progress(t, estrusStart, estrusDuration);
                return 1.0 + (estrusActivityMultiplier - 1.0) * gradualIntensity(progress);
            }
            if (clazz == HerdClass.PREPARTUM && calving != null) {
                // P13: activity rises over the last prepartumActivityRiseHours.
                Instant riseStart = calving.minus(Duration.ofHours(p.prepartumActivityRiseHours()));
                if (!t.isBefore(riseStart) && t.isBefore(calving)) {
                    return p.prepartumActivityMultiplier();
                }
                return 1.0;
            }
            if (clazz == HerdClass.FEVER && feverStart != null
                    && !t.isBefore(feverStart) && t.isBefore(feverEnd)) {
                return 0.7; // illness: activity dampened to 70%
            }
            return 1.0;
        }
    }

    private EventSchedule drawEventSchedule(SimulationHerdParams params, Random rng,
                                            HerdClass herdClass, Instant windowStart) {
        EventSchedule event = new EventSchedule();
        event.clazz = herdClass;
        long totalHours = params.days() * 24L;

        switch (herdClass) {
            case ESTRUS -> {
                // P8: duration U(8,30)h, activity multiplier U(2.5,3.5) around ×3.
                double durationHours = params.estrusDurationLowHours() + rng.nextDouble()
                        * (params.estrusDurationHighHours() - params.estrusDurationLowHours());
                event.estrusDuration = Duration.ofMillis((long) (durationHours * 3600_000.0));
                long maxOffsetHours = Math.max(0, totalHours - (long) Math.ceil(durationHours));
                Instant start = windowStart.plus(Duration.ofHours((long) (rng.nextDouble() * maxOffsetHours)));
                event.estrusStart = start;
                event.estrusActivityMultiplier = params.estrusActivityMultiplier()
                        + (rng.nextDouble() * 2 - 1) * 0.5;
                // Label window = the detectable surge (intensity ≥ 0.5), i.e.
                // the GRADUAL envelope's middle 70%.
                event.label = LabelWindow.ScenarioTypeRef.ESTRUS;
                event.labelStart = start.plus(event.estrusDuration.multipliedBy(15).dividedBy(100));
                event.labelEnd = start.plus(event.estrusDuration.multipliedBy(85).dividedBy(100));
            }
            case PREPARTUM -> {
                // P11: calving lands 1–3 days BEFORE asOf (window tail), so the
                // 24–48h gradual decline and the label window sit fully inside
                // the telemetry window. windowStart + days×24h is exactly asOf.
                double calvingOffsetHours = 24 + rng.nextDouble() * 48;
                event.calving = windowStart
                        .plus(Duration.ofHours(params.days() * 24L))
                        .minus(Duration.ofMillis((long) (calvingOffsetHours * 3600_000.0)));
                // Label window covers the drop window plus margin (plan: [calving−48h, calving]).
                event.label = LabelWindow.ScenarioTypeRef.PREPARTUM;
                event.labelStart = event.calving.minus(Duration.ofHours(48));
                event.labelEnd = event.calving;
            }
            case FEVER -> {
                // P16: ~18h GRADUAL fever placed randomly inside the window
                // (plan wording "随机 2 天" = a random placement, duration from
                // the feverDurationHours parameter, 12–24h band).
                long duration = params.feverDurationHours();
                long maxOffsetHours = Math.max(0, totalHours - duration);
                Instant start = windowStart.plus(Duration.ofHours((long) (rng.nextDouble() * maxOffsetHours)));
                event.feverStart = start;
                event.feverEnd = start.plus(Duration.ofHours(duration));
                event.label = LabelWindow.ScenarioTypeRef.ILLNESS;
                event.labelStart = start;
                event.labelEnd = event.feverEnd;
            }
            case DETACHED -> {
                // Retro-derived: one random 24h block with environmental readings.
                int dayIndex = (int) Math.min(params.days() - 1L,
                        (long) (rng.nextDouble() * params.days()));
                event.detachedDay = windowStart.plus(Duration.ofHours(dayIndex * 24L));
                event.label = LabelWindow.ScenarioTypeRef.DETACHED;
                event.labelStart = event.detachedDay;
                event.labelEnd = event.detachedDay.plus(Duration.ofHours(24));
            }
            default -> {
                // CLEAN: no event, no label.
            }
        }
        return event;
    }

    /** GRADUAL 3-segment envelope (30% ramp / 40% plateau / 30% decay). */
    static double gradualIntensity(double progress) {
        if (progress <= 0 || progress >= 1) {
            return 0;
        }
        if (progress < 0.3) {
            return progress / 0.3;
        }
        if (progress <= 0.7) {
            return 1.0;
        }
        return (1.0 - progress) / 0.3;
    }

    private static double progress(Instant t, Instant start, Duration duration) {
        if (duration.isZero() || t.isBefore(start)) {
            return 0;
        }
        return Duration.between(start, t).toMillis() / (double) duration.toMillis();
    }

    // ------------------------------------------------------------------
    // P5 milking artifact (retro-derived twin bells)
    // ------------------------------------------------------------------

    private double milkingArtifact(SimulationHerdParams params, Instant t, ZonedDateTime zoned) {
        double artifact = 0;
        for (int dayShift = -1; dayShift <= 1; dayShift++) {
            for (double bellHour : MILKING_BELL_HOURS) {
                if (dayShift == -1 && bellHour > 12) {
                    continue; // previous day's late bell is too far to matter
                }
                if (dayShift == 1 && bellHour < 12) {
                    continue; // next day's early bell is too far to matter
                }
                Instant center = zoned.toLocalDate().plusDays(dayShift)
                        .atTime((int) bellHour, 0).atZone(zoned.getZone()).toInstant();
                double deltaMinutes = Math.abs(Duration.between(center, t).toMillis() / 60000.0);
                if (deltaMinutes > MILKING_BELL_CUTOFF_MINUTES) {
                    continue;
                }
                double sigma = MILKING_BELL_SIGMA_MINUTES;
                artifact += (params.milkingArtifactAmplitude() / 2.0)
                        * Math.exp(-(deltaMinutes * deltaMinutes) / (2 * sigma * sigma));
            }
        }
        return artifact;
    }

    // ------------------------------------------------------------------
    // P7 drinking valleys
    // ------------------------------------------------------------------

    /** Poisson(mean) via Knuth sampling, clamped to [low, high]. */
    private int poissonClamped(Random rng, double mean, int low, int high) {
        double limit = Math.exp(-mean);
        int k = 0;
        double p = 1.0;
        do {
            k++;
            p *= rng.nextDouble();
        } while (p > limit);
        return Math.max(low, Math.min(high, k - 1));
    }

    private List<WaterBout> scheduleWaterBouts(SimulationHerdParams params, Random rng,
                                               Instant windowStart) {
        List<WaterBout> bouts = new ArrayList<>();
        // P7 daytime bias anchors to the FARM wall clock: the [06:00, 21:00)
        // placement window is a local-clock statement (cows drink in the local
        // day), so bouts are drawn per LOCAL calendar day.
        ZoneId zone = ZoneId.of(params.farmZoneId());
        LocalDate baseDate = windowStart.atZone(zone).toLocalDate();
        for (int day = 0; day < params.days(); day++) {
            // P7: ~10.5 bouts/animal/day → Poisson(10) truncated to [3,14].
            int count = poissonClamped(rng, params.waterBoutPerDayMean(), 3, 14);
            Instant dayStart = baseDate.plusDays(day).atStartOfDay(zone).toInstant();
            for (int b = 0; b < count; b++) {
                // Bout time biased to daytime: uniform in 06:00–21:00.
                double minuteOffset = 6 * 60 + rng.nextDouble() * (21 * 60 - 6 * 60);
                Instant valleyTime = dayStart.plus(Duration.ofMillis((long) (minuteOffset * 60_000.0)));
                // P7: depth U(2.3, 4.9).
                double depth = params.waterDepthLow() + rng.nextDouble()
                        * (params.waterDepthHigh() - params.waterDepthLow());
                // P7 recovery: Cantor natural-drinking mean 57.75±38.70 min,
                // simulation window 30–120 min (doc §四.1) — parameterized on
                // waterRecoveryMinutes (58) × U(0.5, 2.07) clamped to [30,120].
                double tau = params.waterRecoveryMinutes() * (0.5 + rng.nextDouble() * 1.57);
                tau = Math.max(30.0, Math.min(120.0, tau));
                bouts.add(new WaterBout(valleyTime, depth, tau));
            }
        }
        return bouts;
    }

    /** Precomputes the summed valley contribution per grid point. */
    private double[] valleyContributions(SimulationHerdParams params, List<WaterBout> bouts,
                                         Instant windowStart) {
        int granularity = params.granularityMinutes();
        int pointsPerDay = 24 * 60 / granularity;
        int totalPoints = params.days() * pointsPerDay;
        double[] valley = new double[totalPoints];
        if (bouts.isEmpty()) {
            return valley;
        }
        long stepMillis = granularity * 60_000L;
        long descentMillis = 2L * stepMillis; // "下降 2 点"

        for (WaterBout bout : bouts) {
            double depth = bout.depth();
            long tailMillis = (long) (bout.recoveryTauMinutes() * VALLEY_TAIL_TAUS * 60_000.0);
            Instant from = bout.valleyTime().minusMillis(descentMillis);
            Instant to = bout.valleyTime().plusMillis(tailMillis);
            int fromIndex = indexAt(windowStart, from, stepMillis, totalPoints);
            int toIndex = indexAt(windowStart, to, stepMillis, totalPoints);
            for (int k = Math.max(0, fromIndex); k < Math.min(totalPoints, toIndex + 1); k++) {
                Instant t = windowStart.plusMillis(stepMillis * k);
                if (t.isBefore(bout.valleyTime())) {
                    // Linear descent across the two grid points before the bottom.
                    double beforeMillis = Duration.between(t, bout.valleyTime()).toMillis();
                    if (beforeMillis <= descentMillis) {
                        valley[k] += -depth * (1.0 - beforeMillis / (double) descentMillis);
                    }
                } else {
                    double elapsedMinutes = Duration.between(bout.valleyTime(), t).toMillis() / 60000.0;
                    valley[k] += -depth * Math.exp(-elapsedMinutes / bout.recoveryTauMinutes());
                }
            }
        }
        return valley;
    }

    private int indexAt(Instant windowStart, Instant t, long stepMillis, int totalPoints) {
        long offset = Duration.between(windowStart, t).toMillis();
        if (offset <= 0) {
            return 0;
        }
        return (int) Math.min(totalPoints - 1L, offset / stepMillis);
    }

    private static BigDecimal round2(double value) {
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP);
    }
}
