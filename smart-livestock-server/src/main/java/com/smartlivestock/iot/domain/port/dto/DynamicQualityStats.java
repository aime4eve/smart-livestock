package com.smartlivestock.iot.domain.port.dto;

/**
 * Computed GPS dynamic quality statistics, output of {@code DynamicQualityCalculator}.
 *
 * @param routePointCount  total number of route points (m)
 * @param matchedCount     route points matched within the threshold
 * @param missedCount      route points not matched (GPS failure / not reached)
 * @param ambiguousCount   matched points sharing a GPS report with an adjacent route point
 * @param transitCount     GPS reports not matched to any route point (en-route extras)
 * @param inOrder          matched GPS timestamps are non-decreasing by sequenceNo
 * @param coverage         matchedCount / routePointCount * 100
 * @param meanError        arithmetic mean of matched-point errors (meters)
 * @param p50              50th percentile error (degrades to maxError when matched < 5)
 * @param p95              95th percentile error (degrades to maxError when matched < 20)
 * @param maxError         maximum matched-point error
 */
public record DynamicQualityStats(
    int routePointCount,
    int matchedCount,
    int missedCount,
    int ambiguousCount,
    int transitCount,
    boolean inOrder,
    double coverage,
    double meanError,
    double p50,
    double p95,
    double maxError
) {}
