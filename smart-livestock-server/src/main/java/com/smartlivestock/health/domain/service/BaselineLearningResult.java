package com.smartlivestock.health.domain.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Outcome of one individual baseline learning run (plan 2026-11-03 Task 2).
 * Pure domain value; the caller decides which evidence fields to persist.
 *
 * <p>Semantics:</p>
 * <ul>
 *   <li>Learning succeeded: {@code sourceAfterRun=LEARNED},
 *       {@code baselineTemp}/{@code bandLow}/{@code bandHigh} carry the new
 *       learned values (scale 2, HALF_UP), {@code learnedNow} is true only
 *       when this run flipped the livestock from DEFAULT to LEARNED.</li>
 *   <li>Insufficient data: {@code sourceAfterRun} stays at
 *       {@code previousSource}, {@code learnedNow=false},
 *       {@code baselineTemp} echoes {@code previousBaselineTemp} and the band
 *       is {@code null} — no evidence field is fabricated; whether to skip
 *       persistence is the caller's decision.</li>
 *   <li>{@code excluded} keeps one {@link ExcludedSample} per rejected
 *       sample, in pipeline rejection order, first matching reason only.</li>
 * </ul>
 */
public record BaselineLearningResult(
        String sourceAfterRun,
        boolean learnedNow,
        boolean insufficientData,
        BigDecimal baselineTemp,
        BigDecimal bandLow,
        BigDecimal bandHigh,
        int admittedSampleCount,
        int qualifiedDays,
        Instant windowStart,
        Instant windowEnd,
        List<ExcludedSample> excluded) {

    /**
     * One temperature sample rejected by the admission pipeline, with the
     * first matching rejection reason.
     */
    public record ExcludedSample(Instant recordedAt, BigDecimal temperature,
                                 BaselineAdmissionReason reason) {
    }

    public BaselineLearningResult {
        excluded = List.copyOf(excluded == null ? List.of() : excluded);
    }
}
