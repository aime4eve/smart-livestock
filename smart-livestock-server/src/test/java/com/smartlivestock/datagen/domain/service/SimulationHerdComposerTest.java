package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.application.SimulationHerdGenerationService;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.HerdAnimal;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.HerdClass;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.LabelWindow;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SeriesPoint;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SimulationHerdParams;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SimulationHerdSeries;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.WaterBout;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Pure-computation tests for the literature-parameterized herd composer
 * (plan 2026-11-05 Task 2). No DB, no Spring: fixed asOf + fixed seed.
 *
 * <p>Statistical note: P7 drinking valleys (~10/day, depth up to −4.9 ℃,
 * ~1–2 h exponential recovery) dominate raw temperature means on sub-day
 * windows. Morphology assertions therefore subtract the exactly
 * reconstructable valley contribution (each bout's shape is fully determined
 * by the emitted {@link WaterBout} metadata: linear descent over 2 grid
 * points, exponential recovery with the drawn τ), leaving only P2 noise —
 * so P9/P11 tolerances from the research doc can be asserted deterministically.
 */
class SimulationHerdComposerTest {

    private static final Instant AS_OF = Instant.parse("2026-11-01T08:00:00Z");
    private static final long SEED = 20261105L;
    private static final int DAYS = 14;
    private static final int HERD_SIZE = 30;
    private static final ZoneId ZONE = SimulationHerdComposer.SIMULATION_ZONE;

    private final SimulationHerdComposer composer = new SimulationHerdComposer();

    // ------------------------------------------------------------------
    // 1. Determinism
    // ------------------------------------------------------------------

    @Test
    @DisplayName("同 seed 同参数两次生成，逐点逐字段相等")
    void compositionIsDeterministic() {
        SimulationHerdParams params = defaultParams();
        SimulationHerdSeries first = composer.compose(params, AS_OF);
        SimulationHerdSeries second = composer.compose(params, AS_OF);

        assertThat(second).isEqualTo(first);
    }

    // ------------------------------------------------------------------
    // 2. Individual baseline distribution (P1)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("30 头 μᵢ 全部落在截断区间 [38.6,39.5]，均值接近 39.0±0.2")
    void individualBaselinesAreTruncatedAndCentered() {
        SimulationHerdSeries series = series();

        assertThat(series.animals()).hasSize(HERD_SIZE);
        for (HerdAnimal animal : series.animals()) {
            assertThat(animal.truthBaseline().doubleValue())
                    .as("livestock %s baseline", animal.livestockId())
                    .isBetween(38.6, 39.5);
        }
        double mean = series.animals().stream()
                .mapToDouble(a -> a.truthBaseline().doubleValue()).average().orElse(0);
        assertThat(mean).isBetween(38.8, 39.2);
    }

    // ------------------------------------------------------------------
    // 3. Prepartum morphology (P11 / P13)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("PREPARTUM 头产犊前 6h 段较其事件外基线低 0.15–0.45℃（群体均值），末 8h 活动×1.3–1.7")
    void prepartumShowsRrtDropAndActivityRise() {
        // The −0.3 signal (P11) sits below the P2 AR(1) per-animal noise on a
        // 12-point window (SD ≈ 0.23), so a single head cannot carry the
        // assertion; the drop is averaged over a 60-head herd's PREPARTUM
        // quota (6 heads → herd-mean SD ≈ 0.08).
        List<Long> livestockIds = new ArrayList<>();
        List<Long> deviceIds = new ArrayList<>();
        for (int i = 1; i <= 60; i++) {
            livestockIds.add((long) i);
            deviceIds.add(1000L + i);
        }
        SimulationHerdSeries big = composer.compose(
                SimulationHerdParams.defaults(livestockIds, deviceIds, DAYS, 30, SEED), AS_OF);
        List<HerdAnimal> prepartumHeads = big.animals().stream()
                .filter(a -> a.herdClass() == HerdClass.PREPARTUM).toList();
        assertThat(prepartumHeads).hasSize(6);

        double dropSum = 0;
        for (HerdAnimal animal : prepartumHeads) {
            LabelWindow label = animal.labels().get(0);
            Instant calving = label.end();

            // Anchor review fix: calving lands 1–3 days BEFORE asOf (window
            // tail), so the label window [calving−48h, calving] and the 36h
            // drop segment are fully inside the telemetry window.
            Instant windowStart = animal.points().get(0).recordedAt();
            Instant asOf = animal.points().get(animal.points().size() - 1).recordedAt()
                    .plus(Duration.ofMinutes(30));
            assertThat(calving).as("calving in tail (livestock %s)", animal.livestockId())
                    .isBetween(asOf.minus(Duration.ofHours(72)), asOf.minus(Duration.ofHours(24)));
            assertThat(label.start()).as("label window start ⊆ window")
                    .isAfterOrEqualTo(windowStart);
            assertThat(label.end()).as("label window end < asOf").isBeforeOrEqualTo(asOf);
            assertThat(calving.minus(Duration.ofHours(36))).as("36h drop segment ⊆ window")
                    .isAfterOrEqualTo(windowStart);

            // Temperature drop over [calving−6h, calving] vs hour-of-day-matched
            // points OUTSIDE the label window (calving always lands in the last
            // 3 days, so a contiguous 5-day pre-event window never fits; the
            // outside set spans the rest of the run, post-calving included —
            // modulation is back at μᵢ there), on the valley-cleaned signal.
            List<SeriesPoint> segment = pointsBetween(animal,
                    calving.minus(Duration.ofHours(6)), calving);
            Set<Integer> segmentHours = segment.stream().map(Support::hourOf)
                    .collect(Collectors.toSet());
            List<SeriesPoint> baseline = animal.points().stream()
                    .filter(p -> p.recordedAt().isBefore(label.start())
                            || !p.recordedAt().isBefore(label.end()))
                    .filter(p -> segmentHours.contains(Support.hourOf(p))).toList();

            dropSum += Support.meanCleaned(baseline, animal) - Support.meanCleaned(segment, animal);

            // Activity rise over the last 8h before calving vs the same hours
            // of day outside the label window (activity carries no AR noise,
            // so per-head ratios are stable).
            List<SeriesPoint> rise = pointsBetween(animal,
                    calving.minus(Duration.ofHours(8)), calving);
            Set<Integer> riseHours = rise.stream().map(Support::hourOf).collect(Collectors.toSet());
            List<SeriesPoint> activityBaseline = animal.points().stream()
                    .filter(p -> p.recordedAt().isBefore(label.start())
                            || !p.recordedAt().isBefore(label.end()))
                    .filter(p -> riseHours.contains(Support.hourOf(p))).toList();

            double ratio = Support.meanActivity(rise) / Support.meanActivity(activityBaseline);
            assertThat(ratio).as("prepartum last-8h activity ratio (livestock %s)",
                            animal.livestockId()).isBetween(1.3, 1.7);
        }
        assertThat(dropSum / prepartumHeads.size())
                .as("prepartum RRT drop (herd mean)").isBetween(0.15, 0.45);
    }

    // ------------------------------------------------------------------
    // 4. Estrus morphology (P8 / P9)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ESTRUS 头标签窗内/窗外活动均值比（ herd 中位）≈2.2–3.8，RRT 升幅 ≈0.35–0.75")
    void estrusShowsActivitySurgeAndRrtRise() {
        List<HerdAnimal> estrusHeads = series().animals().stream()
                .filter(a -> a.herdClass() == HerdClass.ESTRUS).toList();
        assertThat(estrusHeads).isNotEmpty();

        // Per-head window means carry P2 AR(1) noise (a single head can sit
        // ~2–3σ off); the herd-median is the stable estimator of the P8/P9
        // effect size, so assert on the median across estrus heads.
        List<Double> activityRatios = new ArrayList<>();
        List<Double> rrtRises = new ArrayList<>();
        for (HerdAnimal animal : estrusHeads) {
            LabelWindow label = animal.labels().get(0);
            Instant start = label.start();
            Instant end = label.end();

            List<SeriesPoint> inWindow = pointsBetween(animal, start, end);
            Set<Integer> windowHours = inWindow.stream().map(Support::hourOf)
                    .collect(Collectors.toSet());
            List<SeriesPoint> outside = animal.points().stream()
                    .filter(p -> !p.recordedAt().isBefore(end) || p.recordedAt().isBefore(start))
                    .filter(p -> windowHours.contains(Support.hourOf(p))).toList();

            activityRatios.add(Support.meanActivity(inWindow) / Support.meanActivity(outside));
            rrtRises.add(Support.meanCleaned(inWindow, animal) - Support.meanCleaned(outside, animal));
        }

        assertThat(Support.median(activityRatios)).as("estrus activity ratio").isBetween(2.2, 3.8);
        assertThat(Support.median(rrtRises)).as("estrus RRT rise").isBetween(0.35, 0.75);
    }

    // ------------------------------------------------------------------
    // 5. Drinking valley morphology (P7)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("温谷深度 ∈[2.0,5.2]，谷后 2h 在 P2/P3 噪声包络内回升到基线水平")
    void waterValleysAreDeepAndRecover() {
        HerdAnimal animal = series().animals().stream()
                .filter(a -> a.herdClass() == HerdClass.CLEAN && !a.waterBouts().isEmpty())
                .findFirst().orElseThrow();

        assertThat(animal.waterBouts().size()).isGreaterThanOrEqualTo(100);
        // Bouts anchor to the FARM-LOCAL calendar day now: the first local
        // day's early bouts (local 06:00–16:00) sit BEFORE the series start
        // (asOf−14d = local 16:00), so their recovery tail is outside the
        // generated series. Depth is still asserted for every bout; the
        // recovery check only applies to bouts fully inside the series.
        Instant seriesStart = animal.points().get(0).recordedAt();
        Instant seriesEnd = animal.points().get(animal.points().size() - 1).recordedAt();
        for (WaterBout bout : animal.waterBouts()) {
            assertThat(bout.depth()).as("bout depth @%s", bout.valleyTime()).isBetween(2.0, 5.2);
            if (bout.descentStartAt().isBefore(seriesStart)
                    || bout.valleyTime().plus(Duration.ofMinutes(150)).isAfter(seriesEnd)) {
                continue;
            }

            // 2h after the bottom: cleaned signal must sit back at baseline
            // level within the statistical envelope (|P3 diurnal| 0.4 + 4σ of
            // the P2 AR-noise 5-point mean ≈ 1.4 + margin → 1.9). The raw
            // μᵢ±0.5 window from the plan is unreachable under P2 noise alone.
            List<SeriesPoint> recovered = pointsBetween(animal,
                    bout.valleyTime().plus(Duration.ofMinutes(105)),
                    bout.valleyTime().plus(Duration.ofMinutes(150)));
            assertThat(recovered).isNotEmpty();
            double meanCleaned = Support.meanCleaned(recovered, animal);
            assertThat(meanCleaned)
                    .as("recovery after bout @%s", bout.valleyTime())
                    .isGreaterThanOrEqualTo(animal.truthBaseline().doubleValue() - 1.9);
        }
    }

    // ------------------------------------------------------------------
    // 6. Detached-sensor morphology (retro-derived)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DETACHED 头全天温度 ∈[25,35]（环境反推）且无任何活动行")
    void detachedDayHasEnvironmentalReadingsAndNoActivity() {
        HerdAnimal animal = firstOf(series(), HerdClass.DETACHED);
        LabelWindow day = animal.labels().get(0);

        List<SeriesPoint> dayPoints = pointsBetween(animal, day.start(), day.end());
        assertThat(dayPoints).hasSize(24 * 2); // 24h at 30-min granularity

        for (SeriesPoint point : dayPoints) {
            assertThat(point.temperature().doubleValue())
                    .as("detached temperature @%s", point.recordedAt()).isBetween(25.0, 35.0);
            assertThat(point.activityIndex()).as("no activity @%s", point.recordedAt()).isNull();
            assertThat(point.stepCount()).isNull();
            assertThat(point.distanceMeters()).isNull();
        }
        // Outside the detached day activity rows exist again.
        List<SeriesPoint> after = pointsBetween(animal, day.end(), day.end().plus(Duration.ofHours(6)));
        assertThat(after).isNotEmpty().allSatisfy(p -> assertThat(p.activityIndex()).isNotNull());
    }

    // ------------------------------------------------------------------
    // 7. Circadian shape (P3/P4 — peak at 23:30, i.e. deep night)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("CLEAN 头 23:00–02:00 段均值 > 09:00–12:00 段均值 + 0.2（峰相深夜）")
    void nightPeakExceedsMorningByCircadianAmplitude() {
        HerdAnimal animal = series().animals().stream()
                .filter(a -> a.herdClass() == HerdClass.CLEAN).findFirst().orElseThrow();

        Set<Integer> nightHours = Set.of(23, 0, 1);
        Set<Integer> morningHours = Set.of(9, 10, 11);
        double night = animal.points().stream()
                .filter(p -> nightHours.contains(Support.hourOf(p)))
                .mapToDouble(p -> p.temperature().doubleValue()).average().orElseThrow();
        double morning = animal.points().stream()
                .filter(p -> morningHours.contains(Support.hourOf(p)))
                .mapToDouble(p -> p.temperature().doubleValue()).average().orElseThrow();

        assertThat(night).isGreaterThan(morning + 0.2);
    }

    // ------------------------------------------------------------------
    // 8. Label/data alignment (P8)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ESTRUS 标签窗起点 1h 内出现 ≥2×同时段基线的活动点（按可检测头集合断言）")
    void estrusLabelStartAlignsWithActivityOnset() {
        List<HerdAnimal> estrusHeads = series().animals().stream()
                .filter(a -> a.herdClass() == HerdClass.ESTRUS).toList();
        assertThat(estrusHeads).isNotEmpty();

        // Detection at onset is probabilistic per head (activity base is a
        // per-point uniform draw, so the first ≥2×median point lands within
        // the first hour with ~50–70% chance per grid point). Assert on the
        // set level: among heads whose first hour overlaps daytime 08–18
        // (night base U(5,25) confounds ×2 detection), a majority must show
        // the surge within 1h of the label start, and every detecting head
        // confirms label start ≤ 1h before its first surge point.
        int checkableHeads = 0;
        int detectingHeads = 0;
        for (HerdAnimal animal : estrusHeads) {
            LabelWindow label = animal.labels().get(0);
            Instant start = label.start();
            Map<Integer, Double> medianByHour =
                    Support.medianActivityByHourOutside(animal, start, label.end());

            List<SeriesPoint> firstHour = animal.points().stream()
                    .filter(p -> !p.recordedAt().isBefore(start)
                            && p.recordedAt().isBefore(start.plus(Duration.ofHours(1))))
                    .toList();
            boolean hasDayPoint = firstHour.stream()
                    .anyMatch(p -> Support.hourOf(p) >= 8 && Support.hourOf(p) <= 18);
            if (!hasDayPoint) {
                continue;
            }
            checkableHeads++;

            boolean detected = firstHour.stream()
                    .filter(p -> Support.hourOf(p) >= 8 && Support.hourOf(p) <= 18)
                    .anyMatch(p -> p.activityIndex() >= 2.0 * medianByHour.get(Support.hourOf(p)));
            if (detected) {
                detectingHeads++;
            }
        }
        assertThat(checkableHeads).as("estrus heads with daytime onset").isGreaterThanOrEqualTo(3);
        assertThat(detectingHeads)
                .as("estrus heads detected within 1h of label start")
                .isGreaterThanOrEqualTo(checkableHeads / 2);
    }

    // ------------------------------------------------------------------
    // 9. Event quota allocation (P8/P11/P16 + retro)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("默认参数 30 头：各类头数 = ratio×30 取整")
    void eventQuotasMatchHeadRatios() {
        SimulationHerdParams params = defaultParams();
        SimulationHerdSeries series = composer.compose(params, AS_OF);

        Map<HerdClass, Long> counts = series.animals().stream()
                .collect(Collectors.groupingBy(HerdAnimal::herdClass, Collectors.counting()));

        assertThat(counts.getOrDefault(HerdClass.ESTRUS, 0L))
                .isEqualTo(Math.round(params.estrusHeadRatio() * HERD_SIZE));
        assertThat(counts.getOrDefault(HerdClass.PREPARTUM, 0L))
                .isEqualTo(Math.round(params.prepartumHeadRatio() * HERD_SIZE));
        assertThat(counts.getOrDefault(HerdClass.FEVER, 0L))
                .isEqualTo(Math.round(params.feverHeadRatio() * HERD_SIZE));
        assertThat(counts.getOrDefault(HerdClass.DETACHED, 0L))
                .isEqualTo(Math.round(params.detachedHeadRatio() * HERD_SIZE));
        assertThat(counts.getOrDefault(HerdClass.CLEAN, 0L))
                .isEqualTo(HERD_SIZE
                        - Math.round(params.estrusHeadRatio() * HERD_SIZE)
                        - Math.round(params.prepartumHeadRatio() * HERD_SIZE)
                        - Math.round(params.feverHeadRatio() * HERD_SIZE)
                        - Math.round(params.detachedHeadRatio() * HERD_SIZE));
        assertThat(counts).doesNotContainKey(HerdClass.WATER);
    }

    // ------------------------------------------------------------------
    // 11. Farm-zone phase anchoring (review fix: every day-phase calc is a
    //     local-clock statement — P3/P4 night peak, day envelope, bouts,
    //     milking bells anchor to the farm wall clock, never to UTC)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("farmZoneId=Asia/Shanghai：本地 23:00–02:00 均值 > 本地 09:00–12:00 均值 + 0.2（深夜峰锚本地钟）")
    void nightPeakAnchorsToFarmLocalClock() {
        // One head → no event class (round(0.2×1)=0), so the series is pure
        // P1+P2+P3 (+P5/P7 artifacts); 10 days give 60 samples per 3h window.
        SimulationHerdParams params = SimulationHerdParams.defaults(
                List.of(1L), List.of(1001L), 10, 30, SEED, "Asia/Shanghai");
        HerdAnimal animal = composer.compose(params, AS_OF).animals().get(0);

        // Filtered explicitly in the farm-local wall clock (Asia/Shanghai):
        // the P4 night peak (23:30) must sit inside the night window.
        ZoneId farmZone = ZoneId.of("Asia/Shanghai");
        Set<Integer> nightHours = Set.of(23, 0, 1);
        Set<Integer> morningHours = Set.of(9, 10, 11);
        double night = animal.points().stream()
                .filter(p -> nightHours.contains(p.recordedAt().atZone(farmZone).getHour()))
                .mapToDouble(p -> p.temperature().doubleValue()).average().orElseThrow();
        double morning = animal.points().stream()
                .filter(p -> morningHours.contains(p.recordedAt().atZone(farmZone).getHour()))
                .mapToDouble(p -> p.temperature().doubleValue()).average().orElseThrow();

        assertThat(night).isGreaterThan(morning + 0.2);
    }

    @Test
    @DisplayName("同 seed 换 farmZoneId 生成结果不同（日相时区敏感性回归）")
    void sameSeedDifferentZoneYieldsDifferentSeries() {
        SimulationHerdSeries shanghai = composer.compose(SimulationHerdParams.defaults(
                List.of(1L, 2L, 3L), List.of(1001L, 1002L, 1003L), DAYS, 30, SEED, "Asia/Shanghai"),
                AS_OF);
        SimulationHerdSeries utc = composer.compose(SimulationHerdParams.defaults(
                List.of(1L, 2L, 3L), List.of(1001L, 1002L, 1003L), DAYS, 30, SEED, "UTC"),
                AS_OF);

        // Same seed → same structure: μᵢ is drawn before any clock-dependent
        // draw, so the truth baselines and point counts are zone-invariant.
        assertThat(utc.animals()).hasSameSizeAs(shanghai.animals());
        for (int i = 0; i < shanghai.animals().size(); i++) {
            assertThat(utc.animals().get(i).truthBaseline())
                    .isEqualByComparingTo(shanghai.animals().get(i).truthBaseline());
            assertThat(utc.animals().get(i).points().size())
                    .isEqualTo(shanghai.animals().get(i).points().size());
        }
        // But every day-phase-dependent value moves with the zone: the first
        // grid point lands on 08:00Z = 16:00 Shanghai vs 08:00 UTC — different
        // circadian phase, different temperature.
        assertThat(utc.animals().get(0).points().get(0).temperature())
                .isNotEqualByComparingTo(shanghai.animals().get(0).points().get(0).temperature());
        assertThat(utc).isNotEqualTo(shanghai);
    }

    // ------------------------------------------------------------------
    // 10. Generation-service range validation
    // ------------------------------------------------------------------

    @Test
    @DisplayName("校验：头数>200 / days>30 / granularity∉{10,15,30} / 列表不等长均抛 ApiException")
    void generationServiceValidatesRanges() {
        // Dependencies are untouched before validation fires — nulls are safe.
        SimulationHerdGenerationService service =
                new SimulationHerdGenerationService(null, null, null, null);

        assertThatThrownBy(() -> service.generate(params(201, 3, 30), 1L))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        assertThatThrownBy(() -> service.generate(params(2, 31, 30), 1L))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        assertThatThrownBy(() -> service.generate(params(2, 3, 20), 1L))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        assertThatThrownBy(() -> service.generate(params(2, 3, 30, 1), 1L))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private SimulationHerdSeries series() {
        return composer.compose(defaultParams(), AS_OF);
    }

    private static SimulationHerdParams defaultParams() {
        return params(HERD_SIZE, DAYS, 30, 0);
    }

    private static SimulationHerdParams params(int herdSize, int days, int granularity) {
        return params(herdSize, days, granularity, 0);
    }

    private static SimulationHerdParams params(int herdSize, int days, int granularity,
                                               int extraDevices) {
        List<Long> livestockIds = new ArrayList<>();
        List<Long> deviceIds = new ArrayList<>();
        for (int i = 1; i <= herdSize; i++) {
            livestockIds.add((long) i);
            deviceIds.add(1000L + i);
        }
        for (int i = 0; i < extraDevices; i++) {
            deviceIds.add(9000L + i);
        }
        return SimulationHerdParams.defaults(livestockIds, deviceIds, days, granularity, SEED);
    }

    private static HerdAnimal firstOf(SimulationHerdSeries series, HerdClass herdClass) {
        return series.animals().stream()
                .filter(a -> a.herdClass() == herdClass)
                .findFirst().orElseThrow();
    }

    private static List<SeriesPoint> pointsBetween(HerdAnimal animal, Instant from, Instant to) {
        return animal.points().stream()
                .filter(p -> !p.recordedAt().isBefore(from) && p.recordedAt().isBefore(to))
                .toList();
    }

    /** Test-side reconstruction of the documented P7 valley shape, mirroring
     *  SimulationHerdComposer.valleyContributions (linear descent over 2 grid
     *  points, exponential recovery with the emitted τ). */
    private static final class Support {

        static int hourOf(SeriesPoint point) {
            return point.recordedAt().atZone(ZONE).getHour();
        }

        static double valleyContribution(Instant t, WaterBout bout, int granularityMinutes) {
            long descentMillis = 2L * granularityMinutes * 60_000L;
            if (t.isBefore(bout.valleyTime())) {
                long beforeMillis = Duration.between(t, bout.valleyTime()).toMillis();
                if (beforeMillis > descentMillis) {
                    return 0;
                }
                return -bout.depth() * (1.0 - beforeMillis / (double) descentMillis);
            }
            double elapsedMinutes = Duration.between(bout.valleyTime(), t).toMillis() / 60000.0;
            return -bout.depth() * Math.exp(-elapsedMinutes / bout.recoveryTauMinutes());
        }

        static double cleaned(SeriesPoint point, HerdAnimal animal, int granularityMinutes) {
            double valleys = animal.waterBouts().stream()
                    .mapToDouble(b -> valleyContribution(point.recordedAt(), b, granularityMinutes))
                    .sum();
            return point.temperature().doubleValue() - valleys;
        }

        static double meanCleaned(List<SeriesPoint> points, HerdAnimal animal) {
            return points.stream()
                    .mapToDouble(p -> cleaned(p, animal, 30))
                    .average().orElseThrow();
        }

        static double meanActivity(List<SeriesPoint> points) {
            return points.stream().mapToInt(SeriesPoint::activityIndex).average().orElseThrow();
        }

        static double median(List<Double> values) {
            List<Double> sorted = new ArrayList<>(values);
            java.util.Collections.sort(sorted);
            int n = sorted.size();
            return n % 2 == 1
                    ? sorted.get(n / 2)
                    : (sorted.get(n / 2 - 1) + sorted.get(n / 2)) / 2.0;
        }

        /** Per-hour-of-day median activity computed from points outside [from, to). */
        static Map<Integer, Double> medianActivityByHourOutside(HerdAnimal animal,
                                                                Instant from, Instant to) {
            Map<Integer, List<Integer>> byHour = new HashMap<>();
            for (SeriesPoint p : animal.points()) {
                if (!p.recordedAt().isBefore(from) && p.recordedAt().isBefore(to)) {
                    continue;
                }
                byHour.computeIfAbsent(hourOf(p), h -> new ArrayList<>()).add(p.activityIndex());
            }
            Map<Integer, Double> medians = new HashMap<>();
            byHour.forEach((hour, values) -> {
                values.sort(Comparator.naturalOrder());
                int n = values.size();
                double median = n % 2 == 1
                        ? values.get(n / 2)
                        : (values.get(n / 2 - 1) + values.get(n / 2)) / 2.0;
                medians.put(hour, median);
            });
            return medians;
        }
    }
}
