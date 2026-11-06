package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import com.smartlivestock.health.infrastructure.config.EstrusScoringProperties;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Task 3 (NIX-380) tests for the dual-path {@link EstrusSeriesReplayer}: the
 * LEGACY short-window formula stays byte-for-byte (regression lock against a
 * hand-computed oracle) and the NORMALIZED path replicates
 * {@code HealthApplicationService.triggerEstrusScoringNormalized} —
 * cross-event-window channel levels, half-open windows, anchor-timestamped
 * activity frames excluded, per-window sample guards, side-independent
 * activity factors, and mode dispatch.
 *
 * <p>Every expected number is hand-computed from the production formulas with
 * the default {@code EstrusScoringProperties} (6h current window, 3×24h
 * baseline windows, 4/4/2 minimum samples, activity ladder 3.0→100 / 2.0→95
 * / 1.5→45, temperature curve over the delta).</p>
 */
class EstrusSeriesReplayerNormalizedTest {

    /** Fixed anchor instant every fixture derives from (no wall-clock dependency). */
    private static final Instant D = Instant.parse("2026-11-01T00:00:00Z");
    private static final long LIVESTOCK_ID = 7L;
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    private final EstrusAnalysisService scoring = new EstrusAnalysisService();

    // ── 1. LEGACY regression lock ────────────────────────────────────

    /**
     * 7 activities (oldest 4 quiet, newest 3 high) before the first
     * temperature give the constant LEGACY features newest-3-vs-rest-4:
     * steps 1200 vs 200 → +500%, distance 1800 vs 200 → +1600 m. Oracle:
     * position T2 (delta 0.00) → 100×0.4 + 0×0.3 + 40.667×0.3 = 52.2 → 52;
     * position T3 (delta 1.40) → 40 + 60×0.3 + 12.2 = 70.2 → 70 (high).
     * Learned side (39.40): last delta 0.50 → 40 + 40×0.3 + 12.2 = 64.2 → 64.
     */
    @Test
    void legacyReplayMatchesHandComputedOracle() {
        EstrusScoringProperties props = new EstrusScoringProperties();
        props.setMode("LEGACY");
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, props);

        List<ActivityLog> acts = new ArrayList<>();
        for (int h = 0; h < 7; h++) {
            acts.add(act(null, h < 4 ? 50 : 400,
                    BigDecimal.valueOf(h < 4 ? 50 : 600),
                    D.minus(Duration.ofHours(14L - h))));
        }
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("38.50", D.minus(Duration.ofHours(6))),
                temp("39.90", D.minus(Duration.ofHours(5))));

        EstrusSeriesReplayer.ReplayResult result = replayer.replay(LIVESTOCK_ID, temps, acts,
                DEFAULT_BASELINE, new BigDecimal("39.40"));

        // DEFAULT side: the 39.9 spike is the only ≥70 position.
        EstrusSeriesReplayer.SideResult defaultSide = result.defaultSide();
        assertEquals(2, defaultSide.scoringPoints());
        assertEquals(1, defaultSide.highScorePoints());
        assertEquals(1, defaultSide.episodes().size());
        assertEquals(List.of(D.minus(Duration.ofHours(5))),
                defaultSide.episodes().get(0).highTimes());
        assertEquals(0, defaultSide.lastTempDelta().compareTo(new BigDecimal("1.40")));
        assertEquals(70, defaultSide.lastScore());

        // LEARNED side: same positions, milder deltas, never ≥70.
        assertNotNull(result.learnedSide());
        assertEquals(2, result.learnedSide().scoringPoints());
        assertEquals(0, result.learnedSide().highScorePoints());
        assertEquals(64, result.learnedSide().lastScore());
        assertEquals(0, result.learnedSide().lastTempDelta().compareTo(new BigDecimal("0.50")));
    }

    // ── 2. NORMALIZED crossing: ratio 3.0 + Δ0.55 → 75, episode ─────

    /**
     * Current window 12×30min frames at activityIndex 180 over three
     * same-phase baseline windows of 12 frames at 60 → ratio exactly 3.0 →
     * activity 100; temperature Δ0.55 → 42; distance unavailable (weight
     * dropped): (100×0.4 + 42×0.3) / 0.7 = 52.6/0.7 = 75.14 → 75 ≥ 70 and one
     * episode. stepCount is flat 10 on purpose: if the kernel mixed channels
     * or fell back to steps the ratio would collapse to 1.0 and the score
     * would drop below 70.
     */
    @Test
    void normalizedCrossingScoresAndProducesEpisode() {
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, new EstrusScoringProperties());

        List<ActivityLog> acts = new ArrayList<>();
        for (int k = 1; k <= 3; k++) acts.addAll(baselineFrames(k, new BigDecimal("60")));
        acts.addAll(currentFrames(new BigDecimal("180")));
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("39.05", D));

        EstrusSeriesReplayer.ReplayResult result = replayer.replay(LIVESTOCK_ID, temps, acts,
                DEFAULT_BASELINE, null);

        EstrusSeriesReplayer.SideResult defaultSide = result.defaultSide();
        // First temperature (i=0) is skipped by the ≥2-samples temperature guard.
        assertEquals(1, defaultSide.scoringPoints());
        assertTrue(defaultSide.lastScore() >= 70, "crossing position must score ≥70, got "
                + defaultSide.lastScore());
        assertEquals(75, defaultSide.lastScore());
        assertEquals(1, defaultSide.highScorePoints());
        assertEquals(1, defaultSide.episodes().size());
        assertEquals(LIVESTOCK_ID, defaultSide.episodes().get(0).livestockId());
        assertEquals(List.of(D), defaultSide.episodes().get(0).highTimes());
        assertEquals(0, defaultSide.lastTempDelta().compareTo(new BigDecimal("0.55")));
        assertNull(result.learnedSide());
    }

    // ── 3. NORMALIZED quiet sequence: ratio 1.0 → no episode ────────

    /**
     * Same frame layout as the crossing test but every level is 60 (ratio
     * 1.0 → activity 0) and temperatures sit on the baseline (Δ0 → temp 0).
     * T2 and T3 both score 0; T1 is skipped by the temperature guard, so
     * scoringPoints = 2 and no episode exists.
     */
    @Test
    void normalizedQuietSequenceProducesNoEpisode() {
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, new EstrusScoringProperties());

        List<ActivityLog> acts = new ArrayList<>();
        for (int k = 1; k <= 3; k++) acts.addAll(baselineFrames(k, new BigDecimal("60")));
        acts.addAll(currentFrames(new BigDecimal("60")));
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("38.50", D),
                temp("38.50", D.plus(Duration.ofHours(2))));

        EstrusSeriesReplayer.ReplayResult result = replayer.replay(temps, acts, DEFAULT_BASELINE, null);

        EstrusSeriesReplayer.SideResult defaultSide = result.defaultSide();
        assertEquals(2, defaultSide.scoringPoints());
        assertEquals(0, defaultSide.highScorePoints());
        assertTrue(defaultSide.episodes().isEmpty());
        assertEquals(0, defaultSide.lastScore());
        assertEquals(0, defaultSide.lastTempDelta().compareTo(BigDecimal.ZERO));
    }

    // ── 4. Anchor-timestamped activity frame excluded ────────────────

    /**
     * One hyper-active frame (activityIndex 9999) is stamped exactly at the
     * anchor temperature T2. NORMALIZED windows are half-open, so the frame
     * must NOT inflate T2's current window (ratio stays 1.0 → score 18 =
     * 42×0.3/0.7, not high), while the NEXT anchor T3 (+2h) does see it
     * (ratio ≈19.4 → activity 100 → score 75). If the tie frame leaked into
     * T2's window the score there would jump to 75 and highScorePoints would
     * be 2 — the assertions below pin the exclusion.
     */
    @Test
    void normalizedExcludesAnchorTimestampedActivityFrame() {
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, new EstrusScoringProperties());

        List<ActivityLog> acts = new ArrayList<>();
        for (int k = 1; k <= 3; k++) acts.addAll(baselineFrames(k, new BigDecimal("60")));
        acts.addAll(currentFrames(new BigDecimal("60")));
        acts.add(act(new BigDecimal("9999"), 9999, null, D));
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("39.05", D),
                temp("39.05", D.plus(Duration.ofHours(2))));

        EstrusSeriesReplayer.ReplayResult result = replayer.replay(temps, acts, DEFAULT_BASELINE, null);

        EstrusSeriesReplayer.SideResult defaultSide = result.defaultSide();
        assertEquals(2, defaultSide.scoringPoints());
        assertEquals(1, defaultSide.highScorePoints(), "only T3 may cross 70; a tie leak would make T2 high too");
        assertEquals(1, defaultSide.episodes().size());
        assertEquals(List.of(D.plus(Duration.ofHours(2))),
                defaultSide.episodes().get(0).highTimes());
        assertEquals(75, defaultSide.lastScore());
    }

    // ── 5. Sparse baseline windows skip the position ─────────────────

    /**
     * With only the first baseline window populated (4 frames), 1 qualified
     * window < ceil(3/2)=2 → the activity component is unavailable and the
     * position is skipped (scoringPoints 0, nothing recorded). Filling the
     * second baseline window as well reaches the 2-window quorum and the very
     * same position scores 75 — the guard reduces scoringPoints, not the
     * score shape.
     */
    @Test
    void normalizedSparseBaselineWindowsSkipPosition() {
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, new EstrusScoringProperties());
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("39.05", D));
        List<ActivityLog> current = currentFrames(new BigDecimal("180"));

        // Scenario A: only k=1 baseline window populated → position skipped.
        List<ActivityLog> sparse = new ArrayList<>(sparseBaselineFrames(1));
        sparse.addAll(current);
        EstrusSeriesReplayer.ReplayResult sparseResult =
                replayer.replay(temps, sparse, DEFAULT_BASELINE, null);
        assertEquals(0, sparseResult.defaultSide().scoringPoints());
        assertEquals(0, sparseResult.defaultSide().highScorePoints());
        assertTrue(sparseResult.defaultSide().episodes().isEmpty());
        assertNull(sparseResult.defaultSide().lastScore());
        assertNull(sparseResult.defaultSide().lastTempDelta());

        // Scenario B: k=1 + k=2 populated → 2 qualified windows → scored.
        List<ActivityLog> sufficient = new ArrayList<>(sparseBaselineFrames(1));
        sufficient.addAll(sparseBaselineFrames(2));
        sufficient.addAll(current);
        EstrusSeriesReplayer.ReplayResult sufficientResult =
                replayer.replay(temps, sufficient, DEFAULT_BASELINE, null);
        assertEquals(1, sufficientResult.defaultSide().scoringPoints());
        assertEquals(75, sufficientResult.defaultSide().lastScore());
        assertEquals(1, sufficientResult.defaultSide().highScorePoints());
    }

    // ── 6. Two sides share activity, differ by baseline ──────────────

    /**
     * Same sequence replayed with DEFAULT 38.50 and LEARNED 39.00: the
     * activity factor is baseline-independent (both sides score the same
     * single position), only tempDelta moves — 0.55 vs 0.05 — so the DEFAULT
     * side reaches 75 (episode) while the learned side lands at
     * (40 + 2.5×0.3)/0.7 = 58.21 → 58 with no episode.
     */
    @Test
    void normalizedSidesShareActivityFactorAndDifferByBaseline() {
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, new EstrusScoringProperties());

        List<ActivityLog> acts = new ArrayList<>();
        for (int k = 1; k <= 3; k++) acts.addAll(baselineFrames(k, new BigDecimal("60")));
        acts.addAll(currentFrames(new BigDecimal("180")));
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("39.05", D));

        EstrusSeriesReplayer.ReplayResult result = replayer.replay(temps, acts,
                DEFAULT_BASELINE, new BigDecimal("39.00"));

        assertNotNull(result.learnedSide());
        EstrusSeriesReplayer.SideResult defaultSide = result.defaultSide();
        EstrusSeriesReplayer.SideResult learnedSide = result.learnedSide();
        // Same positions on both sides (activity/distance factors shared).
        assertEquals(defaultSide.scoringPoints(), learnedSide.scoringPoints());
        assertEquals(1, learnedSide.scoringPoints());
        // Different baselines → different deltas and scores.
        assertEquals(0, defaultSide.lastTempDelta().compareTo(new BigDecimal("0.55")));
        assertEquals(0, learnedSide.lastTempDelta().compareTo(new BigDecimal("0.05")));
        assertEquals(75, defaultSide.lastScore());
        assertEquals(58, learnedSide.lastScore());
        assertEquals(1, defaultSide.highScorePoints());
        assertEquals(0, learnedSide.highScorePoints());
        assertEquals(1, defaultSide.episodes().size());
        assertTrue(learnedSide.episodes().isEmpty());
    }

    // ── 7. Mode dispatch: LEGACY vs NORMALIZED diverge ───────────────

    /**
     * The crossing fixture of test 2 discriminates the two kernels: under
     * LEGACY the newest-7 read sees 7 flat stepCount=10 rows (−25% step
     * increase → step score −10) plus Δ0.55 → 8.6 → 9, no episode; under
     * NORMALIZED the same sequence scores 75 with an episode. Flipping only
     * the mode flips the outcome, proving the dispatch reaches exactly one
     * kernel per call.
     */
    @Test
    void modeDispatchSelectsExactlyOneKernel() {
        EstrusScoringProperties props = new EstrusScoringProperties();
        EstrusSeriesReplayer replayer = new EstrusSeriesReplayer(scoring, props);

        List<ActivityLog> acts = new ArrayList<>();
        for (int k = 1; k <= 3; k++) acts.addAll(baselineFrames(k, new BigDecimal("60")));
        acts.addAll(currentFrames(new BigDecimal("180")));
        List<TemperatureLog> temps = List.of(
                temp("38.50", D.minus(Duration.ofHours(7))),
                temp("39.05", D));

        props.setMode("LEGACY");
        EstrusSeriesReplayer.ReplayResult legacy = replayer.replay(temps, acts, DEFAULT_BASELINE, null);
        assertEquals(1, legacy.defaultSide().scoringPoints());
        assertEquals(9, legacy.defaultSide().lastScore());
        assertEquals(0, legacy.defaultSide().highScorePoints());
        assertTrue(legacy.defaultSide().episodes().isEmpty());

        props.setMode("NORMALIZED");
        EstrusSeriesReplayer.ReplayResult normalized =
                replayer.replay(temps, acts, DEFAULT_BASELINE, null);
        assertEquals(1, normalized.defaultSide().scoringPoints());
        assertEquals(75, normalized.defaultSide().lastScore());
        assertEquals(1, normalized.defaultSide().highScorePoints());
        assertEquals(1, normalized.defaultSide().episodes().size());
    }

    // ── fixture helpers ──────────────────────────────────────────────

    /** Temperature row on the default side's baseline minus/plus a hand-set offset. */
    private static TemperatureLog temp(String value, Instant recordedAt) {
        TemperatureLog log = new TemperatureLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setTemperature(new BigDecimal(value));
        log.setRecordedAt(recordedAt);
        return log;
    }

    /** Activity row; any component may be null to model an unavailable channel. */
    private static ActivityLog act(BigDecimal activityIndex, Integer steps, BigDecimal meters,
                                   Instant recordedAt) {
        ActivityLog log = new ActivityLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setActivityIndex(activityIndex);
        log.setStepCount(steps);
        log.setDistanceMeters(meters);
        log.setRecordedAt(recordedAt);
        return log;
    }

    /**
     * Baseline window k: 12 frames at 30-minute cadence filling the half-open
     * 6h window {@code [D − 24k − 6h, D − 24k)} — exactly the window the
     * production normalized kernel samples for window k (it ENDS 24k hours
     * before the anchor and looks back one current-window length). stepCount
     * stays flat so a wrong channel selection is visible in the ratio.
     */
    private static List<ActivityLog> baselineFrames(int k, BigDecimal level) {
        List<ActivityLog> acts = new ArrayList<>();
        Instant windowStart = D.minus(Duration.ofHours(24L * k + 6));
        for (int j = 0; j < 12; j++) {
            acts.add(act(level, 10, null, windowStart.plus(Duration.ofMinutes(30L * j))));
        }
        return acts;
    }

    /** Current window: 12 frames at 30-minute cadence inside {@code [D − 6h, D)}. */
    private static List<ActivityLog> currentFrames(BigDecimal level) {
        List<ActivityLog> acts = new ArrayList<>();
        for (int j = 0; j < 12; j++) {
            acts.add(act(level, 10, null, D.minus(Duration.ofHours(6)).plus(Duration.ofMinutes(30L * j))));
        }
        return acts;
    }

    /**
     * The first 4 frames of baseline window k (the minimum
     * minBaselineActivitySamples quorum), placed inside the production window
     * {@code [D − 24k − 6h, D − 24k)} — used to build sparse/sufficient
     * baseline layouts for the guard test.
     */
    private static List<ActivityLog> sparseBaselineFrames(int k) {
        List<ActivityLog> acts = new ArrayList<>();
        Instant windowStart = D.minus(Duration.ofHours(24L * k + 6));
        for (int j = 0; j < 4; j++) {
            acts.add(act(new BigDecimal("60"), 10, null,
                    windowStart.plus(Duration.ofMinutes(30L * j))));
        }
        return acts;
    }
}
