package com.smartlivestock.health.application.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * DTOs of the baseline-learning admin endpoints (plan 2026-11-03 Task 5):
 * the manual recalculation write path and the read-only A/B evaluation.
 * All instants are UTC.
 */
public final class BaselineEvaluationDtos {

    private BaselineEvaluationDtos() {}

    /**
     * POST /api/v1/admin/health/baseline-learning/recalculate body:
     * {@code {livestockId?: Long, farmId?: Long}} — one of the two is
     * required; {@code livestockId} wins when both are present. With
     * {@code farmId} every livestock of the farm that owns a health
     * snapshot is recalculated head by head.
     */
    public record BaselineRecalculateRequest(Long livestockId, Long farmId) {}

    /**
     * One head of a manual recalculation. A head that has no snapshot or
     * that threw during its run maps to {@code insufficientData=true} with
     * null evidence fields (the failure reason is logged server-side).
     */
    public record BaselineRecalculateHead(Long livestockId, boolean learnedNow,
                                          BigDecimal baselineTemp, Integer qualifiedDays,
                                          boolean insufficientData) {}

    /**
     * Manual recalculation summary: {@code processed} heads attempted,
     * {@code learnedNow} heads that flipped DEFAULT→LEARNED in this run,
     * one entry per attempted head.
     */
    public record BaselineRecalculateResponse(int processed, int learnedNow,
                                              List<BaselineRecalculateHead> results) {}

    /**
     * POST /api/v1/admin/health/baseline-learning/evaluations body:
     * {@code {livestockId: Long, windowDays?: Integer}} — the override
     * clamps to 7-14 (the same range the configured window validates).
     */
    public record BaselineEvaluationRequest(Long livestockId, Integer windowDays) {}

    /**
     * Read-only A/B evaluation report: ONE identical event sequence
     * (same livestock, same recorded_at window) scored twice — once with
     * the fixed 38.50 DEFAULT baseline, once with the LEARNED candidate the
     * learning kernel would produce (computed in memory, never persisted).
     * {@code learnedSide} is JSON {@code null} when the learned candidate
     * is insufficient (window does not qualify); {@code note} always states
     * that this is a mechanism comparison, not a real false-positive rate.
     */
    public record BaselineEvaluationReport(Long livestockId, Instant windowStart, Instant windowEnd,
                                           Instant evaluatedAt, Side defaultSide, Side learnedSide,
                                           String note) {}

    /**
     * One side of the A/B comparison. {@code bandLow}/{@code bandHigh}/
     * {@code admittedSampleCount}/{@code qualifiedDays} are learning
     * evidence — only the learned side carries them (null on the default
     * side). {@code scoringPoints} counts the event positions the
     * production guard allowed to score; {@code highScorePoints} those with
     * score ≥ 70; {@code episodes} merges consecutive ≥70 positions within
     * 24h; {@code lastTempDelta}/{@code lastScore} sample the final scored
     * position for dev smoke eyeballing.
     */
    public record Side(BigDecimal baselineTemp, BigDecimal bandLow, BigDecimal bandHigh,
                       Integer admittedSampleCount, Integer qualifiedDays,
                       int scoringPoints, int highScorePoints, int episodes,
                       BigDecimal lastTempDelta, Integer lastScore) {}
}
