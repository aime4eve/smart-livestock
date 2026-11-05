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
}
