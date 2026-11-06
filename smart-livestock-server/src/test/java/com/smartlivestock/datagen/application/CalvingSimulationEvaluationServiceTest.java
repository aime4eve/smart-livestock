package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.CalvingSimulationEvaluationService.HeadOutcome;
import com.smartlivestock.datagen.application.dto.SimulationDtos.CalvingEvaluationReport;
import com.smartlivestock.datagen.application.dto.SimulationDtos.PerHeadCalving;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.AlertEpisode;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.CalvingReplayResult;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.ScorePoint;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Metric assembly tests for the calving simulation evaluation (NIX-381 Task
 * 4): the pure {@code assembleReport}/{@code syntheticBreedingAt} functions
 * over hand-built replay outcomes — detection/lead/miss definitions (latest
 * raise at/before the calving instant), the episode-caliber false-alarm rule
 * for non-PREPARTUM heads, per-class channel availability, the non-PREPARTUM
 * rebound hit rate, lead distribution statistics and the scenario-B breeding
 * synthesis. The IO shell around them is deliberately untested here.
 */
class CalvingSimulationEvaluationServiceTest {

    private static final Instant EVALUATED_AT = Instant.parse("2026-11-06T12:00:00Z");
    private static final Instant C1 = Instant.parse("2026-11-05T06:00:00Z");
    private static final Instant C2 = Instant.parse("2026-11-05T12:00:00Z");
    private static final Instant C3 = Instant.parse("2026-11-05T18:00:00Z");

    // ------------------------------------------------------------------
    // Detection / leads / false alarms
    // ------------------------------------------------------------------

    @Test
    void assembleReport_detectionLeadMissAndEpisodeCaliberFalseAlarms() {
        List<HeadOutcome> heads = List.of(
                // Detected: raise 5h before the calving, released 2h before.
                new HeadOutcome(1L, "PREPARTUM", C1,
                        replay(List.of(new AlertEpisode(1L, C1.minus(Duration.ofHours(5)),
                                        C1.minus(Duration.ofHours(2)))),
                                40, 100, 0)),
                // Detected via the LATEST raise at/before calving: an earlier
                // unrelated episode must not win the lead.
                new HeadOutcome(2L, "PREPARTUM", C2,
                        replay(List.of(new AlertEpisode(2L, C2.minus(Duration.ofHours(40)),
                                        C2.minus(Duration.ofHours(36))),
                                new AlertEpisode(2L, C2.minus(Duration.ofHours(10)), null)),
                                10, 50, 0)),
                // Missed: the only raise lands AFTER the calving instant.
                new HeadOutcome(3L, "PREPARTUM", C3,
                        replay(List.of(new AlertEpisode(3L, C3.plus(Duration.ofHours(5)), null)),
                                0, 80, 0)),
                // PREPARTUM without a truth label: unjudgeable — neither
                // detected nor missed, and its episode is not a false alarm.
                new HeadOutcome(4L, "PREPARTUM", null,
                        replay(List.of(new AlertEpisode(4L, C3, null)), 5, 25, 0)),
                // CLEAN head: every episode is a false alarm (episode caliber).
                new HeadOutcome(5L, "CLEAN", null,
                        replay(List.of(new AlertEpisode(5L, C1, C1.plus(Duration.ofHours(2))),
                                        new AlertEpisode(5L, C3, null)),
                                33, 100, 3)));

        CalvingEvaluationReport report = CalvingSimulationEvaluationService.assembleReport(
                9L, EVALUATED_AT, false, heads, "note");

        assertThat(report.runId()).isEqualTo(9L);
        assertThat(report.evaluatedAt()).isEqualTo(EVALUATED_AT);
        assertThat(report.withBreedingPrior()).isFalse();
        assertThat(report.detected()).isEqualTo(2);
        assertThat(report.missed()).isEqualTo(1);
        assertThat(report.leadMinHours()).isEqualTo(5.0);
        assertThat(report.leadMedianHours()).isEqualTo(7.5); // mean of the two middles
        assertThat(report.leadMaxHours()).isEqualTo(10.0);
        assertThat(report.falseAlarmEpisodes()).isEqualTo(2); // only the CLEAN head's episodes
        assertThat(report.note()).isEqualTo("note");

        assertThat(report.perHead()).hasSize(5);
        PerHeadCalving head1 = report.perHead().get(0);
        assertThat(head1.raiseAt()).isEqualTo(C1.minus(Duration.ofHours(5)));
        assertThat(head1.leadHours()).isEqualTo(5.0);
        assertThat(head1.episodeCount()).isEqualTo(1);
        assertThat(head1.tempAvailableRatio()).isEqualTo(0.4);

        PerHeadCalving head2 = report.perHead().get(1);
        assertThat(head2.raiseAt()).isEqualTo(C2.minus(Duration.ofHours(10))); // latest qualifying raise
        assertThat(head2.leadHours()).isEqualTo(10.0);

        PerHeadCalving head3 = report.perHead().get(2);
        assertThat(head3.raiseAt()).isNull(); // a raise after calving is no detection
        assertThat(head3.leadHours()).isNull();

        PerHeadCalving head4 = report.perHead().get(3);
        assertThat(head4.calvingAt()).isNull();
        assertThat(head4.raiseAt()).isNull(); // no calving truth -> no detection claim
        assertThat(head4.episodeCount()).isEqualTo(1); // surfaced, but never a false alarm

        PerHeadCalving head5 = report.perHead().get(4);
        assertThat(head5.herdClass()).isEqualTo("CLEAN");
        assertThat(head5.episodeCount()).isEqualTo(2);
        assertThat(head5.tempAvailableRatio()).isEqualTo(0.33);
    }

    @Test
    void assembleReport_leadDistributionOddMedian() {
        Instant calving = C1;
        List<HeadOutcome> heads = List.of(
                new HeadOutcome(1L, "PREPARTUM", calving, replay(List.of(
                        new AlertEpisode(1L, calving.minus(Duration.ofHours(2)), null)), 1, 1, 0)),
                new HeadOutcome(2L, "PREPARTUM", calving, replay(List.of(
                        new AlertEpisode(2L, calving.minus(Duration.ofHours(9)), null)), 1, 1, 0)),
                new HeadOutcome(3L, "PREPARTUM", calving, replay(List.of(
                        new AlertEpisode(3L, calving.minus(Duration.ofHours(4)), null)), 1, 1, 0)));

        CalvingEvaluationReport report = CalvingSimulationEvaluationService.assembleReport(
                9L, EVALUATED_AT, true, heads, "note");

        assertThat(report.withBreedingPrior()).isTrue();
        assertThat(report.detected()).isEqualTo(3);
        assertThat(report.missed()).isZero();
        assertThat(report.falseAlarmEpisodes()).isZero();
        assertThat(report.leadMinHours()).isEqualTo(2.0);
        assertThat(report.leadMedianHours()).isEqualTo(4.0); // odd count: middle value
        assertThat(report.leadMaxHours()).isEqualTo(9.0);
    }

    // ------------------------------------------------------------------
    // Channel availability / rebound hit rate
    // ------------------------------------------------------------------

    @Test
    void assembleReport_channelAvailabilityGroupedByHerdClassAndReboundRate() {
        List<HeadOutcome> heads = List.of(
                new HeadOutcome(1L, "PREPARTUM", C1, replay(List.of(), 40, 100, 0)),
                new HeadOutcome(2L, "PREPARTUM", C2, replay(List.of(), 10, 50, 0)),
                new HeadOutcome(3L, "CLEAN", null, replay(List.of(), 33, 100, 3)),
                new HeadOutcome(4L, "WATER", null, replay(List.of(), 0, 0, 0)));

        CalvingEvaluationReport report = CalvingSimulationEvaluationService.assembleReport(
                9L, EVALUATED_AT, false, heads, "note");

        assertThat(report.channelAvailability().prepartumAvailablePoints()).isEqualTo(50);
        assertThat(report.channelAvailability().prepartumTotalPoints()).isEqualTo(150);
        assertThat(report.channelAvailability().nonPrepartumAvailablePoints()).isEqualTo(33);
        assertThat(report.channelAvailability().nonPrepartumTotalPoints()).isEqualTo(100);
        // Rebound rate counts only non-PREPARTUM grid points: 3 of 100.
        assertThat(report.reboundHitRateNonPrepartum()).isEqualTo(0.03);
        // A head with no replayed points carries a null ratio.
        assertThat(report.perHead().get(3).tempAvailableRatio()).isNull();
    }

    // ------------------------------------------------------------------
    // Scenario-B breeding synthesis
    // ------------------------------------------------------------------

    @Test
    void syntheticBreedingAt_backwardFromTruthOnlyInRecordScenario() {
        CalvingPredictionProperties p = new CalvingPredictionProperties();

        // Scenario A: never a prior.
        assertThat(CalvingSimulationEvaluationService.syntheticBreedingAt(C1, false, p)).isNull();
        // Scenario B: breeding = ground-truth calving − nominal gestation.
        assertThat(CalvingSimulationEvaluationService.syntheticBreedingAt(C1, true, p))
                .isEqualTo(C1.minus(Duration.ofDays(283)));
        // The nominal gestation is the kernel config value, not a literal.
        p.setGestationDays(280);
        assertThat(CalvingSimulationEvaluationService.syntheticBreedingAt(C1, true, p))
                .isEqualTo(C1.minus(Duration.ofDays(280)));
        // No truth calving -> no synthetic record (prior stays neutral).
        assertThat(CalvingSimulationEvaluationService.syntheticBreedingAt(null, true, p)).isNull();
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /**
     * A replay outcome skeleton: {@code totalPoints} evenly spaced points
     * after 2026-11-01T00:00:00Z with the first {@code reboundCount} flagged,
     * the given episodes and the channel availability counters.
     */
    private static CalvingReplayResult replay(List<AlertEpisode> episodes,
                                              int tempAvailable, int totalPoints, int reboundCount) {
        List<ScorePoint> points = new ArrayList<>(totalPoints);
        Instant base = Instant.parse("2026-11-01T00:00:00Z");
        for (int k = 0; k < totalPoints; k++) {
            points.add(new ScorePoint(base.plus(Duration.ofHours(k)), 0,
                    BigDecimal.ZERO, BigDecimal.ONE, k < reboundCount));
        }
        return new CalvingReplayResult(points, episodes, 0, BigDecimal.ZERO, BigDecimal.ONE,
                tempAvailable, totalPoints);
    }
}
