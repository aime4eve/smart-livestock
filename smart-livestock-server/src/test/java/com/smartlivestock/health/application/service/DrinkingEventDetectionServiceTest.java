package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.service.DrinkingEventDetectionService.DetectionResult;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.ExclusionWindow;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.Params;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.TempPoint;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.Valley;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * Pure unit tests for the drinking detection kernel (NIX-256 Task 3).
 * No Spring context, no Docker — runs anywhere. Time fixtures are wall
 * clocks in Asia/Shanghai (the cow-day zone, F5); defaults of
 * {@link Params#defaults()} mirror spec §14.
 */
class DrinkingEventDetectionServiceTest {

    private static final ZoneId ZONE = DrinkingEventDetectionService.COW_DAY_ZONE;
    private static final Params PARAMS = Params.defaults();

    // ── Fixtures ────────────────────────────────────────────────

    private static Instant at(String wallClock) {
        return LocalDateTime.parse(wallClock).atZone(ZONE).toInstant();
    }

    private static TempPoint point(String wallClock, double temperature) {
        return point(wallClock, temperature, "THINGSBOARD");
    }

    private static TempPoint point(String wallClock, double temperature, String source) {
        return new TempPoint(at(wallClock), temperature, source);
    }

    /** 5-min flat series, inclusive of both ends when aligned. */
    private static List<TempPoint> flat(String from, String to, double temperature) {
        List<TempPoint> points = new ArrayList<>();
        Instant cursor = at(from);
        Instant end = at(to);
        while (!cursor.isAfter(end)) {
            points.add(new TempPoint(cursor, temperature, "THINGSBOARD"));
            cursor = cursor.plusSeconds(5 * 60);
        }
        return points;
    }

    /** Merge series and single points; later arguments win on equal timestamps. */
    @SafeVarargs
    private static List<TempPoint> merge(List<TempPoint>... groups) {
        Map<Instant, TempPoint> byTime = new TreeMap<>();
        for (List<TempPoint> group : groups) {
            group.forEach(p -> byTime.put(p.at(), p));
        }
        return new ArrayList<>(byTime.values());
    }

    private static DetectionResult detect(List<TempPoint> points, String rangeFrom, String rangeTo) {
        return DrinkingEventDetectionService.detectRange(
                points, ZONE, at(rangeFrom), at(rangeTo), List.of(), PARAMS);
    }

    private static DetectionResult detect(List<TempPoint> points, String rangeFrom, String rangeTo,
                                          List<ExclusionWindow> windows) {
        return DrinkingEventDetectionService.detectRange(
                points, ZONE, at(rangeFrom), at(rangeTo), windows, PARAMS);
    }

    // ── 1. V-shaped valley with all criteria passing ────────────

    @Test
    void vShapedValleyDetected() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0),
                        point("2026-06-10T09:35", 37.5),
                        point("2026-06-10T09:40", 36.8),
                        point("2026-06-10T09:45", 37.3),
                        point("2026-06-10T09:50", 38.2),
                        point("2026-06-10T10:00", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.candidates()).isEmpty();
        assertThat(result.events()).hasSize(1);
        Valley event = result.events().get(0);
        assertThat(event.startAt()).isEqualTo(at("2026-06-10T09:30"));
        assertThat(event.troughAt()).isEqualTo(at("2026-06-10T09:40"));
        assertThat(event.minTemp()).isCloseTo(36.8, within(1e-9));
        assertThat(event.tempDrop()).isCloseTo(2.2, within(1e-9));
        assertThat(event.confidence()).isStrictlyBetween(0.0, 1.0);
    }

    // ── 2. Slope passes but depth does not → nothing ────────────

    @Test
    void slopeOnlyValleyNotDetected() {
        // 0.35°C in one 5-min step = 0.07 °C/min ≥ 0.06 (slope passes) but the
        // trough stays within ~0.3°C of the day line μ−0.5σ → r_depth < 0.5,
        // so neither an event nor a borderline candidate may appear.
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0),
                        point("2026-06-10T09:35", 38.65),
                        point("2026-06-10T09:40", 38.8),
                        point("2026-06-10T09:45", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).isEmpty();
        assertThat(result.candidates()).isEmpty();
    }

    // ── 3. No recovery (flat walk after the drop) → nothing ─────

    @Test
    void valleyWithoutRecoveryNotDetected() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T09:30", 39.0),
                List.of(
                        point("2026-06-10T09:35", 37.5),
                        point("2026-06-10T09:40", 36.8)),
                flat("2026-06-10T09:45", "2026-06-10T12:00", 36.85));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).isEmpty();
        assertThat(result.candidates()).isEmpty();
    }

    // ── 4. Merge gap: 10 min apart merges, 40 min does not ──────

    @Test
    void valleysTenMinutesApartMergeIntoOne() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0),
                        point("2026-06-10T09:35", 37.0),
                        point("2026-06-10T09:40", 38.5),
                        point("2026-06-10T09:45", 37.0),
                        point("2026-06-10T09:50", 38.5),
                        point("2026-06-10T09:55", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).hasSize(1);
        Valley event = result.events().get(0);
        assertThat(event.startAt()).isEqualTo(at("2026-06-10T09:30"));   // earliest start
        assertThat(event.minTemp()).isCloseTo(37.0, within(1e-9));       // deepest trough
        assertThat(event.tempDrop()).isCloseTo(2.0, within(1e-9));       // largest drop
    }

    @Test
    void valleysFortyMinutesApartStaySeparate() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0),
                        point("2026-06-10T09:35", 37.0),
                        point("2026-06-10T09:40", 38.5),
                        point("2026-06-10T09:45", 39.0),
                        point("2026-06-10T10:10", 39.0),
                        point("2026-06-10T10:15", 37.0),
                        point("2026-06-10T10:20", 38.5),
                        point("2026-06-10T10:25", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).hasSize(2);
        assertThat(result.events())
                .extracting(Valley::startAt)
                .containsExactly(at("2026-06-10T09:30"), at("2026-06-10T10:10"));
    }

    // ── 5. Fever window: in-window drop, 6h defervescence buffer ─

    @Test
    void valleysInsideFeverWindowAndBufferDropped() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T19:00", 39.0),
                // in-window valley (09:30, window [09:00,10:00))
                List.of(point("2026-06-10T09:30", 39.0), point("2026-06-10T09:35", 37.0),
                        point("2026-06-10T09:45", 38.5), point("2026-06-10T09:55", 39.0)),
                // inside the 6h defervescence buffer (11:00 < 10:00+6h)
                List.of(point("2026-06-10T11:00", 39.0), point("2026-06-10T11:05", 37.0),
                        point("2026-06-10T11:15", 38.5), point("2026-06-10T11:25", 39.0)),
                // after the buffer (17:30 ≥ 16:00) — survives
                List.of(point("2026-06-10T17:30", 39.0), point("2026-06-10T17:35", 37.0),
                        point("2026-06-10T17:45", 38.5), point("2026-06-10T17:55", 39.0)));
        List<ExclusionWindow> windows = List.of(
                new ExclusionWindow(at("2026-06-10T09:00"), at("2026-06-10T10:00")));

        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00", windows);

        assertThat(result.events()).hasSize(1);
        assertThat(result.events().get(0).startAt()).isEqualTo(at("2026-06-10T17:30"));
        assertThat(result.candidates()).isEmpty();
    }

    // ── 6. Out-of-body points (34.9 / 43.1) are skipped ─────────

    @Test
    void outOfBodyPointsSkipped() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                // 43.1 spike: unfiltered it would trigger a false 4°C "descent"
                List.of(point("2026-06-10T08:25", 39.0), point("2026-06-10T08:30", 43.1),
                        point("2026-06-10T08:35", 39.0)),
                // 34.9 out-of-body reading inside the real descent: the trough
                // must stay the last in-body falling point (37.5), not 34.9
                List.of(point("2026-06-10T09:30", 39.0), point("2026-06-10T09:35", 37.5),
                        point("2026-06-10T09:40", 34.9), point("2026-06-10T09:45", 37.6),
                        point("2026-06-10T09:50", 38.9), point("2026-06-10T09:55", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).hasSize(1);
        Valley event = result.events().get(0);
        assertThat(event.startAt()).isEqualTo(at("2026-06-10T09:30"));
        assertThat(event.troughAt()).isEqualTo(at("2026-06-10T09:35"));
        assertThat(event.minTemp()).isCloseTo(37.5, within(1e-9));
        assertThat(event.tempDrop()).isCloseTo(1.5, within(1e-9));
    }

    // ── 7. Source passthrough (user ruling 2026-10-05) ──────────

    @Test
    void eventCarriesSourceOfItsStartPoint() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0, "DATAGEN"),
                        point("2026-06-10T09:35", 37.5),
                        point("2026-06-10T09:40", 36.8),
                        point("2026-06-10T09:50", 38.2),
                        point("2026-06-10T10:00", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).hasSize(1);
        assertThat(result.events().get(0).source()).isEqualTo("DATAGEN");
    }

    // ── 8. Borderline candidates (every criterion ≥ 50%) ────────

    @Test
    void depthJustMissingBecomesCandidate() {
        // Slope (0.15 °C/min) and recovery pass; the trough sits ~0.65°C
        // below μ−0.5σ → r_depth ∈ [0.5, 1): not an event, but borderline.
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0),
                        point("2026-06-10T09:35", 38.25),
                        point("2026-06-10T09:45", 38.9),
                        point("2026-06-10T09:50", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).isEmpty();
        assertThat(result.candidates()).hasSize(1);
        Valley candidate = result.candidates().get(0);
        assertThat(candidate.rDepth()).isBetween(0.5, 1.0);
        assertThat(candidate.confidence()).isLessThan(1.0);
    }

    @Test
    void slowDescentValleyBecomesSingleCandidate() {
        // Three 0.25°C/5-min steps = 0.05 °C/min: r_slope = 0.83 < 1 while
        // depth and recovery pass with margin — borderline. All three trigger
        // pairs share one trough, so exactly one candidate row may appear.
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                List.of(
                        point("2026-06-10T09:30", 39.0),
                        point("2026-06-10T09:35", 38.75),
                        point("2026-06-10T09:40", 38.5),
                        point("2026-06-10T09:45", 38.25),
                        point("2026-06-10T09:55", 38.9),
                        point("2026-06-10T10:00", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).isEmpty();
        assertThat(result.candidates()).hasSize(1);
        Valley candidate = result.candidates().get(0);
        assertThat(candidate.startAt()).isEqualTo(at("2026-06-10T09:30"));
        assertThat(candidate.rSlope()).isBetween(0.5, 1.0);
        assertThat(candidate.minTemp()).isCloseTo(38.25, within(1e-9));
    }

    // ── 9. Confidence monotonicity: deeper valley scores higher ──

    @Test
    void deeperValleyScoresHigherConfidence() {
        List<TempPoint> day = merge(
                flat("2026-06-10T08:00", "2026-06-10T12:00", 39.0),
                // shallow valley: drop to 37.0
                List.of(point("2026-06-10T09:30", 39.0), point("2026-06-10T09:35", 37.0),
                        point("2026-06-10T09:45", 38.2), point("2026-06-10T09:55", 39.0)),
                // deeper valley 40 min later: drop to 36.0
                List.of(point("2026-06-10T10:10", 39.0), point("2026-06-10T10:15", 36.0),
                        point("2026-06-10T10:30", 38.0), point("2026-06-10T10:45", 39.0)));
        DetectionResult result = detect(day, "2026-06-10T00:00", "2026-06-11T00:00");

        assertThat(result.events()).hasSize(2);
        Valley shallow = result.events().stream()
                .filter(v -> v.startAt().equals(at("2026-06-10T09:30"))).findFirst().orElseThrow();
        Valley deep = result.events().stream()
                .filter(v -> v.startAt().equals(at("2026-06-10T10:10"))).findFirst().orElseThrow();
        assertThat(deep.confidence()).isGreaterThan(shallow.confidence());
    }

    // ── 11. Rolling merge anchor: one long descent = one event ──
    // T6 replay finding (2026-10-05): judgeDay emits one candidate per
    // qualifying descent step, so a descent longer than merge-gap used to
    // split into phantom segments at exact +15min multiples when the chain
    // anchor was the merged chain's first start. The gap must compare
    // against the previous member's own start (rolling anchor).

    @Test
    void longDescentMergesIntoSingleEvent() {
        // 20-min descent (5 steps × 0.7°C), trough 10:20, full recovery by 11:00.
        List<TempPoint> descent = new ArrayList<>();
        double temp = 39.2;
        for (int i = 0; i <= 4; i++) {
            descent.add(point(String.format("2026-06-10T%02d:%02d", 10, i * 5), temp));
            temp -= 0.7;
        }
        descent.add(point("2026-06-10T10:20", temp));
        List<TempPoint> points = merge(
                flat("2026-06-10T06:00", "2026-06-10T10:00", 39.2),
                descent,
                flat("2026-06-10T10:25", "2026-06-10T12:00", 39.2));

        DetectionResult result = detect(points, "2026-06-10T00:00", "2026-06-10T23:59");

        assertThat(result.events()).hasSize(1);
        assertThat(result.events().get(0).startAt()).isEqualTo(at("2026-06-10T10:00"));
        assertThat(result.events().get(0).troughAt()).isEqualTo(at("2026-06-10T10:20"));
    }

    @Test
    void mergeEventsRollingAnchorKeepsGenuineSeparateBouts() {
        Valley v1 = new Valley(at("2026-06-10T08:00"), at("2026-06-10T08:10"), 3.0, 36.0, 0.9, "THINGSBOARD", 2, 2, 2);
        Valley v2 = new Valley(at("2026-06-10T08:10"), at("2026-06-10T08:20"), 2.9, 36.1, 0.9, "THINGSBOARD", 2, 2, 2);
        Valley v3 = new Valley(at("2026-06-10T08:20"), at("2026-06-10T08:30"), 2.8, 36.2, 0.9, "THINGSBOARD", 2, 2, 2);
        Valley far = new Valley(at("2026-06-10T09:00"), at("2026-06-10T09:10"), 3.0, 36.0, 0.9, "THINGSBOARD", 2, 2, 2);

        List<Valley> merged = DrinkingEventDetectionService.mergeEvents(
                new ArrayList<>(List.of(v1, v2, v3, far)), 15);

        assertThat(merged).hasSize(2);
        assertThat(merged.get(0).startAt()).isEqualTo(at("2026-06-10T08:00"));
        assertThat(merged.get(0).minTemp()).isEqualTo(36.0);
        assertThat(merged.get(1).startAt()).isEqualTo(at("2026-06-10T09:00"));
    }

    // ── 10. Midnight crossing belongs to the start's local day ──

    @Test
    void midnightCrossingValleyAttributedToStartLocalDay() {
        List<TempPoint> points = merge(
                // local day 1: quiet evening then a descent starting 23:50
                flat("2026-06-10T22:00", "2026-06-10T23:45", 39.0),
                List.of(point("2026-06-10T23:50", 39.0), point("2026-06-10T23:55", 37.0)),
                // local day 2 (hotter baseline — its μ/σ must not own the valley)
                List.of(point("2026-06-11T00:00", 36.8), point("2026-06-11T00:05", 38.0),
                        point("2026-06-11T00:30", 39.1)),
                flat("2026-06-11T00:35", "2026-06-11T02:00", 39.2));
        DetectionResult result = detect(points, "2026-06-10T00:00", "2026-06-11T06:00");

        assertThat(result.events()).hasSize(1);
        Valley event = result.events().get(0);
        assertThat(event.startAt()).isEqualTo(at("2026-06-10T23:50"));
        assertThat(event.troughAt()).isEqualTo(at("2026-06-11T00:00"));
        assertThat(LocalDate.ofInstant(event.startAt(), ZONE)).isEqualTo(LocalDate.of(2026, 6, 10));
    }

    // ── Window extension helper (buffer semantics) ──────────────

    @Test
    void extendWindowsAddsBufferAndKeepsOpenWindowsOpen() {
        List<ExclusionWindow> extended = DrinkingEventDetectionService.extendWindows(
                List.of(
                        new ExclusionWindow(at("2026-06-10T09:00"), at("2026-06-10T10:00")),
                        new ExclusionWindow(at("2026-06-10T12:00"), null)),
                6);

        assertThat(extended).hasSize(2);
        assertThat(extended.get(0).end()).isEqualTo(at("2026-06-10T16:00"));
        assertThat(extended.get(1).end()).isNull();
    }
}
