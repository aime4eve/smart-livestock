package com.smartlivestock.datagen.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * DTOs for the literature-parameterized simulation endpoints
 * (POST /api/v1/admin/datagen/simulation/*).
 */
public final class SimulationDtos {

    private SimulationDtos() {
    }

    /**
     * Request body for POST /herd. farmId is required and validated for
     * existence/access; livestockIds and deviceIds must be equal-length,
     * non-empty lists (1:1 pairing). days/granularityMinutes/seed are
     * optional overrides (defaults: 14 days, 30 min, derived from the window).
     * farmZoneId optionally overrides the farm wall clock every day-phase
     * anchors to (default: Asia/Shanghai — the literature P3/P4/P5/P7 values
     * are local-clock statements).
     */
    public record SimulationHerdGenerateRequest(
            Long farmId,
            List<Long> livestockIds,
            List<Long> deviceIds,
            Integer days,
            Integer granularityMinutes,
            Long seed,
            String farmZoneId) {
    }

    /** One animal's scoring anchor row (simulation_truth_baselines mirror). */
    public record TruthBaselineDto(
            Long livestockId,
            BigDecimal trueBaseline,
            String herdClass) {
    }

    /** Generation outcome for the admin response. */
    public record SimulationHerdRunResult(
            Long runId,
            long seed,
            int herdSize,
            int days,
            long temperatureRows,
            long activityRows,
            Map<String, Integer> labelCounts,
            List<TruthBaselineDto> truthBaselines,
            Instant windowStart,
            Instant windowEnd) {
    }

    /**
     * Request body for POST /evaluation — the simulation run to evaluate.
     * {@code runId} is required and must exist (otherwise RESOURCE_NOT_FOUND).
     */
    public record SimulationEvaluationRequest(Long runId) {
    }

    /**
     * Evaluation report of one simulation run (plan 2026-11-05 Task 3).
     * Three verdict layers: per-head learned-vs-truth baseline rows, the
     * aggregate baseline metrics (global + stratified by herd class, with a
     * manual-calibration proxy column as the comparison anchor) and the
     * estrus mechanism comparison (replayed alert episodes vs ESTRUS label
     * windows, DEFAULT vs LEARNED baseline). {@code note} always states the
     * simulated-data boundary (MessageSource key
     * {@code simulation.evaluation.note}) — this is mechanism/methodology
     * validation, never a real false-positive rate.
     */
    public record SimulationEvaluationReport(
            Long runId,
            Instant evaluatedAt,
            List<PerHeadBaseline> perHead,
            BaselineMetrics baselineMetrics,
            EstrusComparison estrusComparison,
            int insufficientCount,
            int errorCount,
            String note) {
    }

    /**
     * One head of the evaluation. {@code learnedBaseline} is the learned
     * value read back from the health snapshot (present only when
     * {@code learnedSource} is LEARNED); {@code absErr} = |learned − true|
     * and {@code manualProxyAbsErr} = the head's manual-calibration proxy
     * error |ε| — both only populated for heads the learned-metric set
     * covers (learned present, evalStatus OK) so the aggregate columns stay
     * comparable. {@code evalStatus}: OK, or ERROR when the head's
     * recalculate threw (the failure is logged server-side).
     */
    public record PerHeadBaseline(
            Long livestockId,
            String herdClass,
            BigDecimal trueBaseline,
            BigDecimal learnedBaseline,
            String learnedSource,
            Double absErr,
            Double manualProxyAbsErr,
            String evalStatus) {
    }

    /**
     * Baseline metric block: the global aggregate plus one stratum per herd
     * class. {@code mae} = mean |learned − true|, {@code bias} = signed mean
     * (learned − true), {@code hit01}/{@code hit02} = share of heads within
     * ±0.1 / ±0.2 °C, {@code manualMae} = mean proxy error over the same
     * head set (what manual calibration with the documented ε error band
     * would score). Empty strata carry count=0 with null metrics.
     */
    public record BaselineMetrics(BaselineStratum overall, List<BaselineStratum> byHerdClass) {
    }

    public record BaselineStratum(
            String herdClass,
            int count,
            Double mae,
            Double bias,
            Double hit01,
            Double hit02,
            Double manualMae) {
    }

    /**
     * Estrus mechanism comparison, one side per baseline candidate:
     * replayed scoring totals across the run's heads and their alignment
     * against the ESTRUS ground-truth label windows — TP = episode
     * overlapping at least one window of its head, FP = episode overlapping
     * none, FN = window no episode covers. {@code falseAlarmRate} =
     * FP/(TP+FP), null when no episodes were produced at all.
     */
    public record EstrusComparison(EstrusSideResult defaultSide, EstrusSideResult learnedSide) {
    }

    public record EstrusSideResult(
            int episodes,
            int highScorePoints,
            int tp,
            int fp,
            int fn,
            Double falseAlarmRate) {
    }

    // ------------------------------------------------------------------
    // Calving prediction evaluation (NIX-381 Task 4)
    // ------------------------------------------------------------------

    /**
     * Request body for POST /calving-evaluation. {@code runId} is required
     * and must exist (otherwise RESOURCE_NOT_FOUND). {@code withBreedingPrior}
     * selects the evaluation scenario (null = false):
     * <ul>
     *   <li><b>false — scenario A, "no breeding record"</b>: the gestation
     *       prior is unavailable for every head (the conservative basis the
     *       acceptance thresholds apply to).</li>
     *   <li><b>true — scenario B, "record available"</b>: the breeding date is
     *       SYNTHESIZED backwards from the ground-truth calving
     *       ({@code period_end − gestationDays}). This measures the pipeline
     *       WITH a usable record — it is NOT a prediction ability, and every
     *       scenario-B number must be read as such (simulation red line).</li>
     * </ul>
     */
    public record CalvingEvaluationRequest(Long runId, Boolean withBreedingPrior) {
    }

    /**
     * Calving detection evaluation of one simulation run: per head the
     * telemetry window is replayed through the production calving kernel and
     * the shared alert state machine ({@code CalvingSeriesReplayer}), then the
     * alert episodes are aligned against the ground truth. PREPARTUM heads:
     * an episode raised at/before the ground-truth calving instant
     * ({@code ground_truth_labels} PREPARTUM {@code period_end}) is a
     * detection with lead = calving − raise. Non-PREPARTUM heads
     * (CLEAN/WATER/FEVER/ESTRUS/DETACHED): every episode is a false alarm
     * (episode caliber). {@code note} always carries the simulated-data
     * boundary (MessageSource key {@code simulation.evaluation.note}).
     */
    public record CalvingEvaluationReport(
            Long runId,
            Instant evaluatedAt,
            boolean withBreedingPrior,
            int detected,
            int missed,
            Double leadMinHours,
            Double leadMedianHours,
            Double leadMaxHours,
            int falseAlarmEpisodes,
            ChannelAvailability channelAvailability,
            Double reboundHitRateNonPrepartum,
            List<PerHeadCalving> perHead,
            String note) {
    }

    /**
     * Temperature-channel availability (the drinking-exclusion shape leaves
     * the channel dark for most of the day by design, review 2b/2d): grid
     * points with a usable temperature drop vs all replayed grid points,
     * grouped by herd class — the Task 4/7 reports must publish this per
     * class so a detection ceiling is never mistaken for a detector failure.
     */
    public record ChannelAvailability(
            int prepartumAvailablePoints,
            int prepartumTotalPoints,
            int nonPrepartumAvailablePoints,
            int nonPrepartumTotalPoints) {
    }

    /**
     * One head of the calving evaluation. {@code raiseAt} is the matching
     * detection raise (the LATEST episode raise at/before the calving
     * instant) for detected PREPARTUM heads, null otherwise;
     * {@code leadHours} = (calving − raiseAt) in hours; {@code episodeCount}
     * is the head's total episode count (= its false-alarm contribution for
     * non-PREPARTUM heads); {@code tempAvailableRatio} = available/total grid
     * points (null when the head replayed no points).
     */
    public record PerHeadCalving(
            Long livestockId,
            String herdClass,
            Instant raiseAt,
            Instant calvingAt,
            Double leadHours,
            int episodeCount,
            Double tempAvailableRatio) {
    }
}
