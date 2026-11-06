package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.service.CalvingSeriesReplayer.AlertEpisode;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.CalvingReplayResult;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.ScorePoint;
import com.smartlivestock.health.domain.service.CalvingPredictionService;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ActivitySample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ExclusionWindow;
import com.smartlivestock.health.domain.service.CalvingPredictionService.TempSample;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Hand-computed oracle tests for the calving series replayer (NIX-381 Task
 * 4): grid-point scores derived by hand from the documented kernel windows
 * (6h current / 24h+48h same-phase reference, ladders 0.30/0.20/0.12 and
 * 1.5/1.3/1.15, weights 0.45/0.35, rebound on — the working point pinned by
 * {@link #oracleWorkingPoint()}, decoupled from the calibrated defaults of
 * plan 7d), the shared alert state machine over the
 * hourly poll grid, drinking-exclusion buffering, episode raise→release
 * pairing, the cadence-difference lock (30-minute sample cadence fabricates a
 * persistence the hourly production grid correctly refuses), the
 * no-look-ahead guard and the physiological gate (production-replay parity).
 */
class CalvingSeriesReplayerTest {

    private static final Instant NOW = Instant.parse("2026-11-06T12:00:00Z");
    private static final Duration STEP = Duration.ofMinutes(30);

    private final CalvingPredictionProperties properties = oracleWorkingPoint();
    private final CalvingSeriesReplayer replayer =
            new CalvingSeriesReplayer(new CalvingPredictionService(), properties);

    /** The working point the grid oracles were hand-computed on: 6h window,
     *  weights 0.45/0.35/0.20, rebound on. */
    private static CalvingPredictionProperties oracleWorkingPoint() {
        CalvingPredictionProperties p = new CalvingPredictionProperties();
        p.setCurrentTempWindowHours(6);
        p.setWeightTempDrop(0.45);
        p.setWeightActivity(0.35);
        p.setWeightPrior(0.20);
        p.setReboundDetectionEnabled(true);
        return p;
    }

    // ------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------

    private static TempSample temp(double hoursAgo, String celsius) {
        return new TempSample(NOW.minusSeconds(Math.round(hoursAgo * 3600)), new BigDecimal(celsius));
    }

    private static ActivitySample act(double hoursAgo, String index) {
        return new ActivitySample(NOW.minusSeconds(Math.round(hoursAgo * 3600)), new BigDecimal(index));
    }

    /**
     * The prepartum-oracle series: 68 half-hour temperature samples over 34h
     * (38.80 background, a drinking valley sunk by exclusion, a 38.50 decline
     * over the last 6h) plus 68 activity samples (40 background, 60 over the
     * last 7.5h). Grid points before T−8h have no qualified 24h reference
     * (the series starts at T−34h), so the temperature channel is dark there.
     */
    private List<TempSample> oracleTemps() {
        List<TempSample> temps = new ArrayList<>();
        for (int k = 0; k <= 67; k++) {
            double hoursAgo = 34 - 0.5 * k;
            boolean valley = k >= 32 && k <= 37; // inside the buffered exclusion
            boolean decline = k >= 56;           // T−6h .. T−0.5h
            temps.add(temp(hoursAgo, valley ? "35.00" : decline ? "38.50" : "38.80"));
        }
        return temps;
    }

    private List<ActivitySample> oracleActs() {
        List<ActivitySample> acts = new ArrayList<>();
        for (int k = 0; k <= 67; k++) {
            double hoursAgo = 34 - 0.5 * k;
            acts.add(act(hoursAgo, k >= 53 ? "60" : "40")); // 60 from T−7.5h on
        }
        return acts;
    }

    /** Drinking event: descent onset T−18h, trough T−17h → exclusion [−18h, −15h) with the 120min buffer. */
    private static final ExclusionWindow VALLEY_EVENT = new ExclusionWindow(
            NOW.minus(Duration.ofHours(18)), NOW.minus(Duration.ofHours(17)));

    /**
     * Malformed row (trough before start) → clipped to its start:
     * exclusion [−13.5h, −11.5h), covering the samples −13.5h/−13h/−12.5h.
     * Far enough from every reference window (refs end at −24h for the newest
     * grid point) but inside the T−8h stale-window candidates, so a wrong
     * (unclipped) interpretation observably bends the oracle.
     */
    private static final ExclusionWindow INVERTED_EVENT = new ExclusionWindow(
            NOW.minusSeconds(Math.round(13.5 * 3600)), NOW.minusSeconds(Math.round(14.5 * 3600)));

    // ------------------------------------------------------------------
    // Hand-computed oracle
    // ------------------------------------------------------------------

    /**
     * Key grid points (hourly grid anchored at now, 35 points from T−34h):
     * <ul>
     *   <li>T−8h: current [−14h,−8h) 12 clean 38.80 → drop 0.00 (available),
     *       activity 1.00 → score 0 — proves the valley exclusion (without it
     *       the 35.00 samples would sit in earlier windows and wreck the
     *       means) and the buffer (the trough is 1h after the onset).</li>
     *   <li>T−5h: drop 0.05 (temp 0), ratio 1.16 (act 45) → score 20.</li>
     *   <li>T−3h: drop 0.15 (temp 45), ratio 1.28 (act 45) → score 45.</li>
     *   <li>T−2h: drop 0.20, ratio 1.34 → 70 — first crossing only lands the
     *       column (persistence 2), no raise.</li>
     *   <li>T−1h: drop 0.25, ratio 1.41 → 70 — prev 70 crosses → raise.</li>
     *   <li>T: drop 0.30, ratio 1.47 → 87 — hold with the ticket active (the
     *       activity window still holds one 40 sample at its edge).</li>
     * </ul>
     * One episode [raiseAt T−1h, still active at the end → releaseAt null];
     * temperature channel available at the 9 points T−8h..T.
     */
    @Test
    void oracle_handComputedGridScores_episodeAndAvailability() {
        CalvingReplayResult result = replayer.replay(42L, oracleTemps(), oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), null, NOW);

        assertThat(result.totalPoints()).isEqualTo(35);
        assertThat(result.tempChannelAvailablePoints()).isEqualTo(9);

        assertPoint(result, 8, 0, "0.00", "1.00");
        assertPoint(result, 5, 20, "0.05", "1.16");
        assertPoint(result, 3, 45, "0.15", "1.28");
        assertPoint(result, 2, 70, "0.20", "1.34");
        assertPoint(result, 1, 70, "0.25", "1.41");
        assertPoint(result, 0, 87, "0.30", "1.47");

        assertThat(result.lastScore()).isEqualTo(87);
        assertThat(result.lastTempDrop()).isEqualByComparingTo("0.30");
        assertThat(result.lastActivityRatio()).isEqualByComparingTo("1.47");

        assertThat(result.episodes()).hasSize(1);
        AlertEpisode episode = result.episodes().get(0);
        assertThat(episode.livestockId()).isEqualTo(42L);
        assertThat(episode.raiseAt()).isEqualTo(NOW.minus(Duration.ofHours(1)));
        assertThat(episode.releaseAt()).isNull();
    }

    /**
     * Inverted drinking row (trough before start) is clipped to its start —
     * a naive end-based window would be empty (start > end excludes nothing)
     * and let the samples through. With the row planted over
     * −13.5h/−13h/−12.5h the clipped exclusion removes three samples of the
     * T−8h current window (9 clean remain, mean 38.80, drop 0.00, rebound
     * off → score 0); the shock samples are 35.00 — INSIDE the physiological
     * band, so only the exclusion can remove them — and UNexcluded they sink
     * that window's mean to 37.85 (drop 0.95 → temp 100; activity 1.00 is
     * available at 0 and keeps its weight → 56.25, +10 rebound → 66, the same
     * score as the former out-of-band shock since the ladder saturates),
     * observably different, so the clip rule is pinned.
     */
    @Test
    void drinkingExclusion_invertedRowClippedToStart() {
        List<TempSample> temps = oracleTemps();
        for (int k = 41; k <= 43; k++) { // T−13.5h .. T−12.5h
            temps.set(k, temp(34 - 0.5 * k, "35.00"));
        }
        CalvingReplayResult clipped = replayer.replay(null, temps, oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), null, NOW);
        assertPoint(clipped, 8, 0, "0.00", "1.00");

        CalvingReplayResult unexcluded = replayer.replay(null, temps, oracleActs(),
                List.of(), null, NOW);
        assertPoint(unexcluded, 8, 66, "0.95", "1.00");
        assertThat(unexcluded.points()).isNotEqualTo(clipped.points());
    }

    // ------------------------------------------------------------------
    // Cadence lock: the production poll grid vs a sample-pacing replay
    // ------------------------------------------------------------------

    /**
     * 73 half-hour samples (T−36h..T): 38.80 background, a step down to 38.50
     * at T−4.5h, no activity — the score is the temperature ladder alone.
     * <ul>
     *   <li>Hourly grid (production pollMs): T−1h drop 0.18 → 45 (column
     *       reset, sub-persist), T drop 0.23 → 70 with prev null → crossed is
     *       FALSE → the crossing only lands the score. NO episode.</li>
     *   <li>30-minute grid: T−0.5h drop 0.20 → 70 lands the column, T (70)
     *       then finds prev 70 → crossed → raise. An episode fabricates two
     *       "consecutive" evaluations 30 minutes apart that the production
     *       scheduler never takes.</li>
     * </ul>
     * This locks the replay cadence to pollMs: the persistence semantics only
     * mean something at the production evaluation rhythm.
     */
    @Test
    void replayCadence_pollGridRefusesWhatSamplePacingFabricates() {
        List<TempSample> temps = new ArrayList<>();
        for (int k = 0; k <= 72; k++) {
            double hoursAgo = 36 - 0.5 * k;
            temps.add(temp(hoursAgo, k >= 63 ? "38.50" : "38.80")); // step at T−4.5h
        }

        // Production cadence (default pollMs 1h).
        CalvingReplayResult hourly = replayer.replay(null, temps, List.of(), List.of(),
                null, NOW);
        assertThat(hourly.totalPoints()).isEqualTo(37);
        assertPoint(hourly, 1, 45, "0.18", null);
        assertPoint(hourly, 0, 70, "0.23", null);
        assertThat(hourly.episodes()).isEmpty();
        assertThat(hourly.lastScore()).isEqualTo(70);

        // Sample pacing: the same sequence on a 30-minute grid.
        properties.setPollMs(1_800_000L);
        CalvingReplayResult halfHour = replayer.replay(null, temps, List.of(), List.of(),
                null, NOW);
        assertThat(halfHour.totalPoints()).isEqualTo(73);
        assertPoint(halfHour, 1, 45, "0.18", null);
        assertPoint(halfHour, 0, 70, "0.23", null);
        assertThat(halfHour.episodes()).hasSize(1);
        assertThat(halfHour.episodes().get(0).raiseAt()).isEqualTo(NOW);
        assertThat(halfHour.episodes().get(0).releaseAt()).isNull();
    }

    /**
     * Full raise→release pairing through the shared state machine: decline
     * (38.80→38.40 at −12.5h) with an activity surge (60) — the column climbs
     * 59 → 76, the prev-76/score-87 pair crosses at T−7h → RAISE; the hold
     * band tracks 87/87/80/66 (the rebound bonus is visible in 80 = 70+10);
     * the recovery to 38.90 plus the activity fall drops the score to 30
     * (20 + rebound 10) < 55 → RELEASE at T−2h. The tail stays quiet (no
     * re-open). Grid values verified against the kernel trace of this fixture.
     */
    @Test
    void episode_raiseAndReleasePairedThroughSharedState() {
        List<TempSample> temps = new ArrayList<>();
        List<ActivitySample> acts = new ArrayList<>();
        for (int k = 0; k <= 71; k++) {
            double hoursAgo = 36 - 0.5 * k;
            String temp = hoursAgo > 12.5 ? "38.80" : hoursAgo >= 6 ? "38.40" : "38.90";
            String actIdx = hoursAgo > 12.5 ? "40" : hoursAgo >= 6 ? "60" : "40";
            temps.add(temp(hoursAgo, temp));
            acts.add(act(hoursAgo, actIdx));
        }

        CalvingReplayResult result = replayer.replay(7L, temps, acts, List.of(), null, NOW);
        assertThat(result.totalPoints()).isEqualTo(37);
        assertThat(result.tempChannelAvailablePoints()).isEqualTo(11); // T−10h..T

        assertPoint(result, 9, 59, "0.23", "1.22");
        assertPoint(result, 8, 76, "0.30", "1.28");
        assertPoint(result, 7, 87, "0.37", "1.34"); // prev 76 crosses -> raise here
        assertPoint(result, 6, 87, "0.40", "1.41"); // hold, no re-raise
        assertPoint(result, 4, 80, "0.28", "1.41"); // 70 + rebound 10, hold band
        assertPoint(result, 3, 66, "0.19", "1.34"); // 56 + rebound 10, still >= 55: hold
        assertPoint(result, 2, 30, "0.11", "1.28"); // 20 + rebound 10 < 55 -> release here
        assertPoint(result, 0, 20, "-0.06", "1.16"); // quiet tail, no re-open

        assertThat(result.episodes()).hasSize(1);
        assertThat(result.episodes().get(0).livestockId()).isEqualTo(7L);
        assertThat(result.episodes().get(0).raiseAt()).isEqualTo(NOW.minus(Duration.ofHours(7)));
        assertThat(result.episodes().get(0).releaseAt()).isEqualTo(NOW.minus(Duration.ofHours(2)));
        assertThat(result.lastScore()).isEqualTo(20);
    }

    // ------------------------------------------------------------------
    // No look-ahead
    // ------------------------------------------------------------------

    /**
     * Samples stamped after the evaluation baseline never participate: the
     * grid is anchored at now and only inputs with at ≤ t are visible, so
     * appending future telemetry reproduces the baseline replay bit for bit.
     */
    @Test
    void noLookAhead_samplesAfterNowIgnored() {
        CalvingReplayResult baseline = replayer.replay(null, oracleTemps(), oracleActs(),
                List.of(VALLEY_EVENT), null, NOW);

        List<TempSample> withFuture = new ArrayList<>(oracleTemps());
        for (int k = 1; k <= 4; k++) {
            withFuture.add(temp(-0.5 * k, "40.00")); // after NOW: 40 °C shock
        }
        List<ActivitySample> withFutureActs = new ArrayList<>(oracleActs());
        withFutureActs.add(act(-0.5, "9999"));

        CalvingReplayResult guarded = replayer.replay(null, withFuture, withFutureActs,
                List.of(VALLEY_EVENT), null, NOW);

        assertThat(guarded.points()).isEqualTo(baseline.points());
        assertThat(guarded.episodes()).isEqualTo(baseline.episodes());
        assertThat(guarded.lastScore()).isEqualTo(baseline.lastScore());
    }

    // ------------------------------------------------------------------
    // Physiological gate (production-replay parity)
    // ------------------------------------------------------------------

    /**
     * Detached-sensor readings never enter the replayed temperature channel,
     * exactly like production: 30.00 °C (and one 45.00 °C) samples planted
     * between the oracle samples — at T−0.25h, T−3.25h, T−5.75h, T−9.25h and
     * T−26.25h, outside both drinking windows so only the gate can drop them —
     * replay to the baseline bit for bit. Ungated, the T−8h point alone would
     * read a drop of 0.98 instead of 0.00 (its current window keeps 8 clean
     * 38.80 samples plus the planted 30.00 → mean 37.82) and the score track
     * would move.
     */
    @Test
    void physiologicalGate_detachedSamplesNeverEnterTemperatureChannel() {
        CalvingReplayResult baseline = replayer.replay(42L, oracleTemps(), oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), null, NOW);

        List<TempSample> withDetached = new ArrayList<>(oracleTemps());
        withDetached.add(temp(0.25, "30.00"));
        withDetached.add(temp(3.25, "45.00"));
        withDetached.add(temp(5.75, "30.00"));
        withDetached.add(temp(9.25, "30.00"));
        withDetached.add(temp(26.25, "30.00"));
        CalvingReplayResult gated = replayer.replay(42L, withDetached, oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), null, NOW);

        assertThat(gated.points()).isEqualTo(baseline.points());
        assertThat(gated.episodes()).isEqualTo(baseline.episodes());
        assertThat(gated.tempChannelAvailablePoints()).isEqualTo(baseline.tempChannelAvailablePoints());
        assertPoint(gated, 0, 87, "0.30", "1.47");
    }

    /** An empty series replays to nothing: no points, no episodes, null tails. */
    @Test
    void emptySeries_replaysToEmptyResult() {
        CalvingReplayResult result = replayer.replay(null, List.of(), List.of(), List.of(),
                null, NOW);
        assertThat(result.points()).isEmpty();
        assertThat(result.episodes()).isEmpty();
        assertThat(result.lastScore()).isNull();
        assertThat(result.lastTempDrop()).isNull();
        assertThat(result.lastActivityRatio()).isNull();
        assertThat(result.tempChannelAvailablePoints()).isZero();
        assertThat(result.totalPoints()).isZero();
    }

    /**
     * The breeding prior rides the replay per grid point, exactly like the
     * production gestation read. Scenario B (record available): breeding =
     * ground-truth calving − 283d → 282 days pregnant at T−2h → NORMAL prior
     * (full weight counted): T−8h (0+0+20)/1.0 = 20 vs 0 without a prior,
     * T−2h (31.5+24.5+20)/1.0 = 76 vs 70, episode still raises at T−1h.
     * Fresh breeding inside the series (record 3h old): before the breeding
     * instant the prior is neutral (T−4h = 20), from T−3h on the 0-day
     * gestation SUPPRESSES (weighted total ×0.5 → 18/28/35) and the
     * suppressed scores never reach the alert line — no episode at all.
     */
    @Test
    void breedingPrior_perGridPointGestationDays_normalSuppressedAndNeutral() {
        // Scenario B: NORMAL prior at every grid point.
        Instant calving = NOW.plus(Duration.ofHours(6));
        Instant breeding = calving.minus(Duration.ofDays(283)); // 282d pregnant at T−2h
        CalvingReplayResult recordAvailable = replayer.replay(null, oracleTemps(), oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), breeding, NOW);
        assertPoint(recordAvailable, 8, 20, "0.00", "1.00");
        assertPoint(recordAvailable, 5, 36, "0.05", "1.16");
        assertPoint(recordAvailable, 3, 56, "0.15", "1.28");
        assertPoint(recordAvailable, 2, 76, "0.20", "1.34");
        assertPoint(recordAvailable, 0, 90, "0.30", "1.47"); // (45+24.5+20)/1.0 = 89.5 -> 90
        assertThat(recordAvailable.episodes()).hasSize(1);
        assertThat(recordAvailable.episodes().get(0).raiseAt()).isEqualTo(NOW.minus(Duration.ofHours(1)));

        // A fresh record 3h old: neutral before it, suppressed after.
        Instant freshBreeding = NOW.minus(Duration.ofHours(3));
        CalvingReplayResult suppressed = replayer.replay(null, oracleTemps(), oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), freshBreeding, NOW);
        assertPoint(suppressed, 4, 20, "0.10", "1.22"); // t < breeding: neutral, base score
        assertPoint(suppressed, 3, 18, "0.15", "1.28"); // 0d pregnant: (20.25+15.75+0)/1.0 × 0.5 = 18
        assertPoint(suppressed, 2, 28, "0.20", "1.34"); // 56 × 0.5
        assertPoint(suppressed, 0, 35, "0.30", "1.47"); // 69.5 × 0.5 = 34.75 -> 35
        assertThat(suppressed.episodes()).isEmpty();    // suppressed scores never cross 70

        CalvingReplayResult noPrior = replayer.replay(null, oracleTemps(), oracleActs(),
                List.of(VALLEY_EVENT, INVERTED_EVENT), null, NOW);
        assertPoint(noPrior, 2, 70, "0.20", "1.34");
        assertPoint(noPrior, 4, 20, "0.10", "1.22");
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /** The grid point {@code hoursAgo} hours before now: score and features. */
    private void assertPoint(CalvingReplayResult result, double hoursAgo, int score,
                             String tempDrop, String activityRatio) {
        ScorePoint point = pointAt(result, hoursAgo);
        assertThat(point.score())
                .as("score at T−%sh", hoursAgo)
                .isEqualTo(score);
        if (tempDrop == null) {
            assertThat(point.tempDrop()).as("tempDrop at T−%sh", hoursAgo).isNull();
        } else {
            assertThat(point.tempDrop()).as("tempDrop at T−%sh", hoursAgo).isEqualByComparingTo(tempDrop);
        }
        if (activityRatio == null) {
            assertThat(point.activityRatio()).as("activityRatio at T−%sh", hoursAgo).isNull();
        } else {
            assertThat(point.activityRatio()).as("activityRatio at T−%sh", hoursAgo)
                    .isEqualByComparingTo(activityRatio);
        }
    }

    private ScorePoint pointAt(CalvingReplayResult result, double hoursAgo) {
        Instant at = NOW.minusSeconds(Math.round(hoursAgo * 3600));
        return result.points().stream()
                .filter(p -> p.at().equals(at))
                .findFirst()
                .orElseThrow(() -> new AssertionError("no grid point at " + at));
    }
}
