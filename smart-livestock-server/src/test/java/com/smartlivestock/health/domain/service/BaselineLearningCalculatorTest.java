package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.ACTIVE_PERIOD;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.ACTIVITY_UNKNOWN;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.DRINKING_WINDOW;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.DUPLICATE;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.FEVER_ALERT_WINDOW;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.IMPLAUSIBLE;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.ROBUST_OUTLIER;
import static com.smartlivestock.health.domain.service.BaselineAdmissionReason.SOURCE_NOT_ALLOWED;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for the pure baseline learning kernel (plan 2026-11-03 Task 2).
 * Pure construction, no mocks, no Spring context. Each test maps to one or
 * more pipeline steps documented on {@link BaselineLearningCalculator}.
 *
 * <p>Fixture convention: farm zone Asia/Shanghai (UTC+8, no DST), base
 * {@code asOf = 2026-11-04T00:00:00Z}, so the default 10-day window covers
 * {@code [2026-10-25T00:00Z, 2026-11-04T00:00Z)} and 22:00 local evening
 * samples land on 14:00Z of the same local day (night per hour >= 21).</p>
 */
class BaselineLearningCalculatorTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final Instant AS_OF = Instant.parse("2026-11-04T00:00:00Z");
    private static final BaselineLearningCalculator CALCULATOR = new BaselineLearningCalculator();

    // ---------------------------------------------------------------- fixtures

    private static TemperatureLog temp(Instant recordedAt, String value, String source) {
        TemperatureLog t = new TemperatureLog();
        t.setLivestockId(1L);
        t.setDeviceId(900L);
        t.setTemperature(new BigDecimal(value));
        t.setRecordedAt(recordedAt);
        t.setSource(source);
        t.setBaselineSource("DEFAULT");
        return t;
    }

    private static TemperatureLog temp(Instant recordedAt, String value) {
        return temp(recordedAt, value, "MANUAL_IMPORT");
    }

    private static ActivityLog activity(Instant recordedAt, String activityIndex) {
        ActivityLog a = new ActivityLog();
        a.setLivestockId(1L);
        a.setDeviceId(900L);
        a.setRecordedAt(recordedAt);
        a.setActivityIndex(new BigDecimal(activityIndex));
        a.setSource("MANUAL_IMPORT");
        return a;
    }

    /** Farm-local wall clock to Instant (Asia/Shanghai). */
    private static Instant at(LocalDate localDate, int hour, int minute) {
        return localDate.atTime(hour, minute).atZone(ZONE).toInstant();
    }

    private static BaselineExclusionWindow window(Instant start, Instant end) {
        return new BaselineExclusionWindow(start, end);
    }

    /** {@code days} local days starting at {@code firstDay}, two night samples each. */
    private static List<TemperatureLog> stableNights(int days, LocalDate firstDay, String low, String high) {
        List<TemperatureLog> list = new ArrayList<>();
        for (int i = 0; i < days; i++) {
            LocalDate day = firstDay.plusDays(i);
            list.add(temp(at(day, 22, 0), low));
            list.add(temp(at(day, 22, 30), high));
        }
        return list;
    }

    private static BaselineLearningInput.Builder baseInput(Instant asOf) {
        return BaselineLearningInput.builder()
                .livestockId(1L)
                .asOf(asOf)
                .farmZone(ZONE);
    }

    // ------------------------------------------------- 1) normal elevated cow

    @Test
    void learnsElevatedIndividualFromDefaultColdStart() {
        // Steps b-f admit all, g keeps all (dev 0.2 <= 3x0.2), h/i: 8 qualified days.
        List<TemperatureLog> temps = stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6");

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.learnedNow()).isTrue();
        assertThat(result.insufficientData()).isFalse();
        assertThat(result.sourceAfterRun()).isEqualTo("LEARNED");
        assertThat(result.baselineTemp()).isEqualByComparingTo("39.40");
        assertThat(result.bandLow()).isEqualByComparingTo("39.00");
        assertThat(result.bandHigh()).isEqualByComparingTo("39.80");
        assertThat(result.qualifiedDays()).isEqualTo(8);
        assertThat(result.admittedSampleCount()).isEqualTo(16);
        assertThat(result.excluded()).isEmpty();
        assertThat(result.windowEnd()).isEqualTo(AS_OF);
        assertThat(result.windowStart()).isEqualTo(at(LocalDate.of(2026, 10, 27), 22, 0));
    }

    // ------------------------------------- 2) fever alert window, LEARNED cow

    @Test
    void feverAlertWindowExcludesSampleWhenPreviousSourceIsLearned() {
        List<TemperatureLog> temps = stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6");
        Instant feverAt = at(LocalDate.of(2026, 11, 3), 23, 30); // 15:30Z, night
        temps.add(temp(feverAt, "40.8"));
        // Active alert window around the sample; +6h fever buffer keeps it covering.
        BaselineExclusionWindow alert = window(
                feverAt.minus(Duration.ofMinutes(30)), feverAt.plus(Duration.ofMinutes(30)));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF)
                .previousSource("LEARNED")
                .previousBaselineTemp(new BigDecimal("39.40"))
                .temperatures(temps)
                .feverAlertWindows(List.of(alert))
                .build());

        assertThat(result.excluded()).hasSize(1);
        assertThat(result.excluded().get(0).recordedAt()).isEqualTo(feverAt);
        assertThat(result.excluded().get(0).temperature()).isEqualByComparingTo("40.8");
        assertThat(result.excluded().get(0).reason()).isEqualTo(FEVER_ALERT_WINDOW);
        assertThat(result.admittedSampleCount()).isEqualTo(16);
        assertThat(result.insufficientData()).isFalse();
        // Already LEARNED before: re-learn succeeds but no DEFAULT->LEARNED flip this run.
        assertThat(result.sourceAfterRun()).isEqualTo("LEARNED");
        assertThat(result.learnedNow()).isFalse();
        assertThat(result.baselineTemp()).isEqualByComparingTo("39.40");
    }

    // --------------------------- 3) DEFAULT cold start is not vetoed by fever

    @Test
    void defaultColdStartDoesNotVetoHighSampleAsFeverAlert() {
        Instant highAt = at(LocalDate.of(2026, 11, 3), 23, 30);

        // Scenario A: same shape as the learning test plus 40.8, no windows at
        // all. Cold start: the sample is never tagged FEVER_ALERT_WINDOW; it
        // stays inside the MAD band (dev 1.2 == threshold 1.2, not ">") and is
        // admitted.
        List<TemperatureLog> loose = stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6");
        loose.add(temp(highAt, "40.8"));
        BaselineLearningResult scenarioA =
                CALCULATOR.calculate(baseInput(AS_OF).temperatures(loose).build());

        assertThat(scenarioA.excluded()).isEmpty();
        assertThat(scenarioA.admittedSampleCount()).isEqualTo(17);
        assertThat(scenarioA.learnedNow()).isTrue();
        assertThat(scenarioA.baselineTemp()).isEqualByComparingTo("39.46");

        // Scenario B: tighter individual — 40.8 leaves the 3xMAD band and must
        // surface as ROBUST_OUTLIER, never as FEVER_ALERT_WINDOW.
        List<TemperatureLog> tight = stableNights(8, LocalDate.of(2026, 10, 27), "39.3", "39.5");
        tight.add(temp(highAt, "40.8"));
        BaselineLearningResult scenarioB =
                CALCULATOR.calculate(baseInput(AS_OF).temperatures(tight).build());

        assertThat(scenarioB.excluded()).hasSize(1);
        assertThat(scenarioB.excluded().get(0).recordedAt()).isEqualTo(highAt);
        assertThat(scenarioB.excluded().get(0).reason()).isEqualTo(ROBUST_OUTLIER);
        assertThat(scenarioB.excluded()).noneSatisfy(e ->
                assertThat(e.reason()).isEqualTo(FEVER_ALERT_WINDOW));
        assertThat(scenarioB.learnedNow()).isTrue();
        assertThat(scenarioB.baselineTemp()).isEqualByComparingTo("39.40");
    }

    // ------------------------------------------ 4) slow fever ramp vs MAD band

    @Test
    void slowFeverRampIsRobustOutlierAndDoesNotRaiseBaseline() {
        List<TemperatureLog> temps = stableNights(7, LocalDate.of(2026, 10, 26), "38.4", "38.5");
        // +0.3 °C steps on the last day; median/MAD of the whole window still
        // anchors on the stable days (MAD 0.1, threshold 0.3).
        temps.add(temp(at(LocalDate.of(2026, 11, 3), 22, 0), "39.1"));
        temps.add(temp(at(LocalDate.of(2026, 11, 3), 22, 10), "39.4"));
        temps.add(temp(at(LocalDate.of(2026, 11, 3), 22, 20), "39.7"));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.excluded()).hasSize(3).allSatisfy(e ->
                assertThat(e.reason()).isEqualTo(ROBUST_OUTLIER));
        assertThat(result.admittedSampleCount()).isEqualTo(14);
        assertThat(result.qualifiedDays()).isEqualTo(7);
        assertThat(result.learnedNow()).isTrue();
        // Baseline stays on the stable days: the ramp never lifts it.
        assertThat(result.baselineTemp()).isEqualByComparingTo("38.45");
        assertThat(result.bandLow()).isEqualByComparingTo("38.35");
        assertThat(result.bandHigh()).isEqualByComparingTo("38.55");
    }

    // ------------------------------------------ 5) drinking trough + recovery

    @Test
    void drinkingWindowExcludesTroughVicinityButKeepsRecoveredSamples() {
        List<TemperatureLog> temps = new ArrayList<>();
        LocalDate firstDay = LocalDate.of(2026, 10, 27);
        for (int i = 0; i < 8; i++) {
            if (i == 4) {
                continue; // Oct 31 is the drinking day, built explicitly below
            }
            LocalDate day = firstDay.plusDays(i);
            temps.add(temp(at(day, 22, 0), "39.2"));
            temps.add(temp(at(day, 22, 30), "39.6"));
        }
        LocalDate drinkingDay = LocalDate.of(2026, 10, 31);
        Instant trough = at(drinkingDay, 20, 0); // 12:00Z
        temps.add(temp(trough.plus(Duration.ofMinutes(90)), "39.0"));  // 21:30 local, inside recovery window
        temps.add(temp(trough.plus(Duration.ofMinutes(150)), "39.4")); // 22:30 local, recovered
        temps.add(temp(at(drinkingDay, 22, 10), "39.2"));
        temps.add(temp(at(drinkingDay, 22, 40), "39.6"));
        // Drinking interval spans start..trough; the kernel appends the 120min recovery itself.
        BaselineExclusionWindow drinking = window(trough, trough);

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF)
                .temperatures(temps)
                .drinkingWindows(List.of(drinking))
                .build());

        assertThat(result.excluded()).hasSize(1);
        assertThat(result.excluded().get(0).recordedAt()).isEqualTo(trough.plus(Duration.ofMinutes(90)));
        assertThat(result.excluded().get(0).reason()).isEqualTo(DRINKING_WINDOW);
        // The 150-minute sample survived (not in excluded) and the day still qualifies.
        assertThat(result.admittedSampleCount()).isEqualTo(17);
        assertThat(result.qualifiedDays()).isEqualTo(8);
        assertThat(result.learnedNow()).isTrue();
        assertThat(result.baselineTemp()).isEqualByComparingTo("39.40");
    }

    // ---------------------------------------------- 6) off-body implausible

    @Test
    void offBodyReadingIsRejectedAsImplausible() {
        List<TemperatureLog> temps = stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6");
        Instant offBodyAt = at(LocalDate.of(2026, 10, 28), 23, 0);
        temps.add(temp(offBodyAt, "27.0"));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.excluded()).hasSize(1);
        assertThat(result.excluded().get(0).recordedAt()).isEqualTo(offBodyAt);
        assertThat(result.excluded().get(0).temperature()).isEqualByComparingTo("27.0");
        assertThat(result.excluded().get(0).reason()).isEqualTo(IMPLAUSIBLE);
        assertThat(result.admittedSampleCount()).isEqualTo(16);
        assertThat(result.learnedNow()).isTrue();
    }

    // ------------------------------------- 7) DATAGEN / UNKNOWN source refusal

    @Test
    void datagenAndUnknownSourcesAreNeverAdmitted() {
        List<TemperatureLog> temps = stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6");
        Instant datagenAt = at(LocalDate.of(2026, 10, 28), 23, 0);
        Instant unknownAt = at(LocalDate.of(2026, 10, 28), 23, 10);
        temps.add(temp(datagenAt, "37.5", "DATAGEN"));
        temps.add(temp(unknownAt, "37.6", "UNKNOWN"));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.excluded()).hasSize(2);
        assertThat(result.excluded()).allSatisfy(e ->
                assertThat(e.reason()).isEqualTo(SOURCE_NOT_ALLOWED));
        assertThat(result.excluded()).anySatisfy(e -> {
            assertThat(e.recordedAt()).isEqualTo(datagenAt);
            assertThat(e.temperature()).isEqualByComparingTo("37.5");
        });
        assertThat(result.excluded()).anySatisfy(e -> {
            assertThat(e.recordedAt()).isEqualTo(unknownAt);
            assertThat(e.temperature()).isEqualByComparingTo("37.6");
        });
        assertThat(result.admittedSampleCount()).isEqualTo(16);
        assertThat(result.learnedNow()).isTrue();
        assertThat(result.baselineTemp()).isEqualByComparingTo("39.40");
    }

    // ------------------------------------------------------ 8) logical dedup

    @Test
    void duplicateFramesCountExactlyOnce() {
        List<TemperatureLog> temps = stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6");
        TemperatureLog last = temps.get(temps.size() - 1); // Nov 3 22:30 local, 39.6
        temps.add(temp(last.getRecordedAt(), "39.6")); // same (deviceId, recordedAt, source)

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.excluded()).filteredOn(e -> e.reason() == DUPLICATE).hasSize(1);
        assertThat(result.excluded().stream()
                .filter(e -> e.reason() == DUPLICATE)
                .findFirst().orElseThrow().recordedAt())
                .isEqualTo(last.getRecordedAt());
        assertThat(result.admittedSampleCount()).isEqualTo(16);
        assertThat(result.qualifiedDays()).isEqualTo(8);
        assertThat(result.learnedNow()).isTrue();
        assertThat(result.baselineTemp()).isEqualByComparingTo("39.40");
    }

    // ------------------------------------------------- 9) activity-based mode

    @Test
    void activityModeClassifiesHighLowAndMissingActivity() {
        LocalDate firstDay = LocalDate.of(2026, 10, 27);
        Instant lowNear = at(firstDay, 21, 55);            // 5min before idx 10 frame
        Instant highNear = at(firstDay.plusDays(1), 21, 58); // 2min before idx 40 frame
        Instant nightNoJoin = at(firstDay.plusDays(2), 22, 0);   // night, no frame nearby
        Instant dayNoJoin = at(firstDay.plusDays(3), 10, 0);     // daytime, no frame nearby
        List<TemperatureLog> temps = List.of(
                temp(lowNear, "39.3"),
                temp(highNear, "39.5"),
                temp(nightNoJoin, "39.4"),
                temp(dayNoJoin, "39.0"));
        // Activity median of {10, 20, 30, 40} = 25; idx 10 -> quiet, idx 40 -> active.
        List<ActivityLog> activities = List.of(
                activity(at(firstDay, 22, 0), "10"),
                activity(at(firstDay.plusDays(1), 22, 0), "40"),
                activity(at(firstDay.plusDays(3), 22, 0), "30"),
                activity(at(firstDay.plusDays(4), 22, 0), "20"));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF)
                .temperatures(temps)
                .activities(activities)
                .build());

        assertThat(result.excluded()).anySatisfy(e -> {
            assertThat(e.recordedAt()).isEqualTo(highNear);
            assertThat(e.reason()).isEqualTo(ACTIVE_PERIOD);
        });
        assertThat(result.excluded()).anySatisfy(e -> {
            assertThat(e.recordedAt()).isEqualTo(dayNoJoin);
            assertThat(e.reason()).isEqualTo(ACTIVITY_UNKNOWN);
        });
        assertThat(result.excluded()).noneSatisfy(e ->
                assertThat(e.recordedAt()).isIn(lowNear, nightNoJoin));
        assertThat(result.admittedSampleCount()).isEqualTo(2);
        // Scattered single samples: no day reaches minSamplesPerDay.
        assertThat(result.insufficientData()).isTrue();
    }

    // ------------------------------------- 10) night fallback without activity

    @Test
    void withoutAnyActivityNightSamplesAreKeptAndDaySamplesDropped() {
        Instant dayAt = at(LocalDate.of(2026, 10, 27), 10, 0);  // 02:00Z
        Instant nightAt = at(LocalDate.of(2026, 10, 27), 22, 0); // 14:00Z
        List<TemperatureLog> temps = List.of(temp(dayAt, "39.0"), temp(nightAt, "39.2"));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.excluded()).hasSize(1);
        assertThat(result.excluded().get(0).recordedAt()).isEqualTo(dayAt);
        assertThat(result.excluded().get(0).reason()).isEqualTo(ACTIVE_PERIOD);
        assertThat(result.admittedSampleCount()).isEqualTo(1);
        assertThat(result.insufficientData()).isTrue();
    }

    // ------------------------------------------------- 11) window boundaries

    @Test
    void windowBoundariesAreHalfOpen() {
        Instant asOf = Instant.parse("2026-11-04T16:00:00Z");
        Instant startBoundary = asOf.minus(Duration.ofDays(10)); // 2026-10-25T16:00Z
        List<TemperatureLog> temps = List.of(
                temp(startBoundary, "39.0"),                  // exactly at start -> included
                // companion sample on the same local day so the day qualifies
                // (windowStart counts qualified-day samples only)
                temp(startBoundary.plusSeconds(1800), "39.4"), // 00:30 local, still night
                temp(startBoundary.minusSeconds(60), "39.1"),  // before start -> trimmed silently
                temp(asOf, "39.2"));                           // at asOf -> trimmed (half-open end)

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(asOf).temperatures(temps).build());

        assertThat(result.admittedSampleCount()).isEqualTo(2);
        assertThat(result.excluded()).isEmpty();
        assertThat(result.insufficientData()).isTrue();
        assertThat(result.windowStart()).isEqualTo(startBoundary);
        assertThat(result.windowEnd()).isEqualTo(asOf);
    }

    // ------------------------------------------- 12) insufficient qualified days

    @Test
    void insufficientQualifiedDaysKeepPreviousSourceAndBaseline() {
        List<TemperatureLog> temps = new ArrayList<>();
        LocalDate firstDay = LocalDate.of(2026, 10, 27);
        for (int i = 0; i < 6; i++) { // 6 days x 3 samples, minQualifiedDays = 7
            LocalDate day = firstDay.plusDays(i);
            temps.add(temp(at(day, 22, 0), "39.0"));
            temps.add(temp(at(day, 22, 15), "39.1"));
            temps.add(temp(at(day, 22, 30), "39.2"));
        }

        BaselineLearningResult fromDefault = CALCULATOR.calculate(baseInput(AS_OF)
                .previousSource("DEFAULT")
                .previousBaselineTemp(new BigDecimal("38.50"))
                .temperatures(temps)
                .build());

        assertThat(fromDefault.insufficientData()).isTrue();
        assertThat(fromDefault.learnedNow()).isFalse();
        assertThat(fromDefault.sourceAfterRun()).isEqualTo("DEFAULT");
        assertThat(fromDefault.baselineTemp()).isEqualByComparingTo("38.50");
        assertThat(fromDefault.bandLow()).isNull();
        assertThat(fromDefault.bandHigh()).isNull();
        assertThat(fromDefault.qualifiedDays()).isEqualTo(6);
        assertThat(fromDefault.admittedSampleCount()).isEqualTo(18);
        assertThat(fromDefault.windowEnd()).isEqualTo(AS_OF);

        // Already LEARNED livestock keeps its learned value on a stale window.
        BaselineLearningResult fromLearned = CALCULATOR.calculate(baseInput(AS_OF)
                .previousSource("LEARNED")
                .previousBaselineTemp(new BigDecimal("39.10"))
                .temperatures(temps)
                .build());

        assertThat(fromLearned.insufficientData()).isTrue();
        assertThat(fromLearned.learnedNow()).isFalse();
        assertThat(fromLearned.sourceAfterRun()).isEqualTo("LEARNED");
        assertThat(fromLearned.baselineTemp()).isEqualByComparingTo("39.10");
    }

    // --------------------------------------------- 13) shuffle determinism

    @Test
    void shuffledInputProducesIdenticalOutcome() {
        List<TemperatureLog> temps = new ArrayList<>(
                stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6"));
        Instant dupAt = at(LocalDate.of(2026, 10, 29), 22, 5);
        temps.add(temp(dupAt, "39.4"));
        temps.add(temp(dupAt, "39.6")); // duplicate key with a different value:
        // canonical order keeps the lower temperature regardless of input order
        temps.add(temp(at(LocalDate.of(2026, 10, 28), 23, 0), "37.5", "DATAGEN"));
        temps.add(temp(at(LocalDate.of(2026, 10, 28), 23, 10), "37.6", "UNKNOWN"));
        temps.add(temp(at(LocalDate.of(2026, 10, 30), 23, 0), "27.0"));
        temps.add(temp(AS_OF.minus(Duration.ofDays(10)).minusSeconds(3600), "39.0")); // out of window
        temps.add(temp(AS_OF, "39.0")); // at asOf -> trimmed

        BaselineLearningInput ordered = baseInput(AS_OF).temperatures(temps).build();
        List<TemperatureLog> shuffledList = new ArrayList<>(temps);
        Collections.shuffle(shuffledList, new Random(42));
        BaselineLearningInput shuffled = baseInput(AS_OF).temperatures(shuffledList).build();

        BaselineLearningResult a = CALCULATOR.calculate(ordered);
        BaselineLearningResult b = CALCULATOR.calculate(shuffled);

        // Field-by-field equality; excluded happens to match in order too
        // because the pipeline walks a canonical order, but per the spec the
        // excluded comparison below is order-insensitive.
        assertThat(b.sourceAfterRun()).isEqualTo(a.sourceAfterRun());
        assertThat(b.learnedNow()).isEqualTo(a.learnedNow());
        assertThat(b.insufficientData()).isEqualTo(a.insufficientData());
        assertThat(b.baselineTemp()).isEqualByComparingTo(a.baselineTemp());
        assertThat(b.bandLow()).isEqualByComparingTo(a.bandLow());
        assertThat(b.bandHigh()).isEqualByComparingTo(a.bandHigh());
        assertThat(b.admittedSampleCount()).isEqualTo(a.admittedSampleCount());
        assertThat(b.qualifiedDays()).isEqualTo(a.qualifiedDays());
        assertThat(b.windowStart()).isEqualTo(a.windowStart());
        assertThat(b.windowEnd()).isEqualTo(a.windowEnd());
        assertThat(b.excluded())
                .usingRecursiveFieldByFieldElementComparator()
                .containsExactlyInAnyOrderElementsOf(a.excluded());
        assertThat(b).isEqualTo(a);

        // Expected outcome of the mixed input.
        assertThat(a.learnedNow()).isTrue();
        assertThat(a.baselineTemp()).isEqualByComparingTo("39.40");
        assertThat(a.qualifiedDays()).isEqualTo(8);
        assertThat(a.admittedSampleCount()).isEqualTo(17);
        assertThat(a.excluded()).hasSize(4);
        assertThat(a.excluded())
                .extracting(BaselineLearningResult.ExcludedSample::reason)
                .containsExactlyInAnyOrder(SOURCE_NOT_ALLOWED, SOURCE_NOT_ALLOWED, IMPLAUSIBLE, DUPLICATE);
        assertThat(a.excluded())
                .filteredOn(e -> e.reason() == DUPLICATE)
                .allSatisfy(e -> assertThat(e.temperature()).isEqualByComparingTo("39.6"));
    }

    // ----------------------------------------------- 14) MAD = 0 -> mad floor

    @Test
    void zeroMadFallsBackToMadFloorAndKeepsIdenticalSamples() {
        List<TemperatureLog> temps = stableNights(7, LocalDate.of(2026, 10, 27), "38.5", "38.5");
        Instant outlierAt = at(LocalDate.of(2026, 11, 3), 22, 0);
        temps.add(temp(outlierAt, "40.0"));

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.excluded()).hasSize(1);
        assertThat(result.excluded().get(0).recordedAt()).isEqualTo(outlierAt);
        assertThat(result.excluded().get(0).reason()).isEqualTo(ROBUST_OUTLIER);
        // The 14 identical samples survive thanks to the 0.05 floor.
        assertThat(result.admittedSampleCount()).isEqualTo(14);
        assertThat(result.qualifiedDays()).isEqualTo(7);
        assertThat(result.learnedNow()).isTrue();
        assertThat(result.baselineTemp()).isEqualByComparingTo("38.50");
        assertThat(result.bandLow()).isEqualByComparingTo("38.50");
        assertThat(result.bandHigh()).isEqualByComparingTo("38.50");
    }

    // ------------------------------------- 15) dense backfill cannot dominate

    @Test
    void denseBackfillDayDoesNotDominateBaseline() {
        List<TemperatureLog> temps = new ArrayList<>();
        LocalDate firstSparseDay = LocalDate.of(2026, 10, 26);
        for (int i = 0; i < 7; i++) { // 7 sparse days x 15 night samples
            LocalDate day = firstSparseDay.plusDays(i);
            for (int j = 0; j < 15; j++) {
                temps.add(temp(at(day, 22, 0).plusSeconds(j * 60L), j < 8 ? "38.0" : "39.0"));
            }
        }
        LocalDate denseDay = LocalDate.of(2026, 11, 2);
        for (int j = 0; j < 100; j++) { // one dense day with 100 night samples at 41.0
            temps.add(temp(at(denseDay, 22, 0).plusSeconds(j * 60L), "41.0"));
        }

        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF).temperatures(temps).build());

        assertThat(result.learnedNow()).isTrue();
        assertThat(result.qualifiedDays()).isEqualTo(8);
        assertThat(result.admittedSampleCount()).isEqualTo(205);
        // Per-day weight 1: dense day contributes 1/8, so the baseline stays
        // near the sparse days (a naive unweighted mean would be ~39.70).
        assertThat(result.baselineTemp()).isLessThanOrEqualTo(new BigDecimal("39.0"));
        assertThat(result.baselineTemp()).isEqualByComparingTo("38.78");
    }

    // ------------------------------------------- 16) band shape and precision

    @Test
    void bandStrictlySurroundsBaselineAtFixedScale() {
        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF)
                .temperatures(stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6"))
                .build());

        assertThat(result.bandLow()).isLessThan(result.baselineTemp());
        assertThat(result.bandHigh()).isGreaterThan(result.baselineTemp());
        assertThat(result.baselineTemp().scale()).isEqualTo(2);
        assertThat(result.bandLow().scale()).isEqualTo(2);
        assertThat(result.bandHigh().scale()).isEqualTo(2);
    }

    // --------------------------- 17) re-learn under LEARNED does not flip again

    @Test
    void relearnUnderLearnedSourceUpdatesValuesWithoutFlip() {
        BaselineLearningResult result = CALCULATOR.calculate(baseInput(AS_OF)
                .previousSource("LEARNED")
                .previousBaselineTemp(new BigDecimal("39.00"))
                .temperatures(stableNights(8, LocalDate.of(2026, 10, 27), "39.2", "39.6"))
                .build());

        assertThat(result.insufficientData()).isFalse();
        assertThat(result.sourceAfterRun()).isEqualTo("LEARNED");
        assertThat(result.learnedNow()).isFalse();
        // Recomputed from the window, not echoing the previous value.
        assertThat(result.baselineTemp()).isEqualByComparingTo("39.40");
    }

    // ── FEVER_ELEVATED: LEARNED re-learning excludes samples ≥1.0°C over the
    // frozen pre-learning baseline even when no alert window covers them
    // (plan §1.2.3; catches recorded_at < created_at alert latency). ──

    @org.junit.jupiter.api.Test
    void learnedRerun_excludesSampleElevatedOverFrozenBaseline_withoutAlertWindow() {
        // 8 qualified nights at 39.30/39.40/39.50 plus one 40.80 spike (no
        // alert window supplied): the spike must drop via FEVER_ELEVATED.
        java.util.List<com.smartlivestock.health.domain.model.TemperatureLog> temps = new java.util.ArrayList<>();
        java.time.Instant base = java.time.Instant.parse("2026-06-01T21:30:00Z");
        for (int d = 0; d < 8; d++) {
            temps.add(temp(base.minus(java.time.Duration.ofDays(d)), "39.30"));
            temps.add(temp(base.minus(java.time.Duration.ofDays(d)).plusSeconds(3600), "39.40"));
            temps.add(temp(base.minus(java.time.Duration.ofDays(d)).plusSeconds(7200), "39.50"));
        }
        temps.add(temp(base.plusSeconds(900), "40.80"));

        BaselineLearningResult result = CALCULATOR.calculate(BaselineLearningInput.builder()
                .livestockId(1L).asOf(base.plusSeconds(9000)).farmZone(java.time.ZoneId.of("UTC"))
                .previousSource("LEARNED").previousBaselineTemp(new java.math.BigDecimal("39.40"))
                .temperatures(temps).activities(java.util.List.of())
                .illnessWindows(java.util.List.of()).feverAlertWindows(java.util.List.of())
                .drinkingWindows(java.util.List.of()).build());

        org.assertj.core.api.Assertions.assertThat(
                result.excluded().stream()
                        .anyMatch(e -> e.reason() == BaselineAdmissionReason.FEVER_ELEVATED
                                && e.temperature().compareTo(new java.math.BigDecimal("40.80")) == 0))
                .as("40.80 spike must be excluded via FEVER_ELEVATED").isTrue();
        org.assertj.core.api.Assertions.assertThat(result.insufficientData())
                .as("re-learning must actually qualify, not echo the previous value")
                .isFalse();
        org.assertj.core.api.Assertions.assertThat(result.baselineTemp())
                .as("baseline must stay at the quiet-state level")
                .isEqualByComparingTo(new java.math.BigDecimal("39.40"));
    }

    @org.junit.jupiter.api.Test
    void defaultColdStart_ignoresFrozenBaselineExclusion() {
        // DEFAULT cold start: previous baseline 38.50, sample 39.50 (delta 1.0)
        // must NOT be excluded by the frozen-baseline rule — only windows/MAD
        // apply (plan §1.2.3 cold-start veto rule).
        java.util.List<com.smartlivestock.health.domain.model.TemperatureLog> temps = new java.util.ArrayList<>();
        java.time.Instant base = java.time.Instant.parse("2026-06-01T21:30:00Z");
        for (int d = 0; d < 8; d++) {
            temps.add(temp(base.minus(java.time.Duration.ofDays(d)), "39.30"));
            temps.add(temp(base.minus(java.time.Duration.ofDays(d)).plusSeconds(3600), "39.40"));
            temps.add(temp(base.minus(java.time.Duration.ofDays(d)).plusSeconds(7200), "39.50"));
        }
        temps.add(temp(base.plusSeconds(900), "39.50"));

        BaselineLearningResult result = CALCULATOR.calculate(BaselineLearningInput.builder()
                .livestockId(1L).asOf(base.plusSeconds(9000)).farmZone(java.time.ZoneId.of("UTC"))
                .previousSource("DEFAULT").previousBaselineTemp(new java.math.BigDecimal("38.50"))
                .temperatures(temps).activities(java.util.List.of())
                .illnessWindows(java.util.List.of()).feverAlertWindows(java.util.List.of())
                .drinkingWindows(java.util.List.of()).build());

        org.assertj.core.api.Assertions.assertThat(
                result.excluded().stream()
                        .anyMatch(e -> e.reason() == BaselineAdmissionReason.FEVER_ELEVATED))
                .as("DEFAULT cold start must never apply the frozen-baseline veto").isFalse();
        org.assertj.core.api.Assertions.assertThat(result.insufficientData()).isFalse();
    }
}