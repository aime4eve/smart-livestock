package com.smartlivestock.iot.domain.port.dto;

import com.smartlivestock.iot.domain.model.QualityGrade;

/**
 * Computed GPS quality statistics, output of {@code GpsQualityCalculator}.
 *
 * @param totalPoints     total number of GPS points in the input
 * @param suspectPoints   points with active telemetry (stepNumber > 0)
 * @param effectivePoints points used for statistics (total − suspect when excluded)
 * @param meanError       arithmetic mean of effective-point errors (meters)
 * @param p50             50th percentile error
 * @param p95             95th percentile error (max approximation when N < 20)
 * @param p99             99th percentile error; {@code null} when N < 100
 * @param maxError        maximum error among effective points
 * @param jitterDiameter  maximum pairwise haversine distance (meters)
 * @param outlierCount    effective points whose error exceeds the outlier threshold
 * @param grade           quality grade derived from p95 and effective sample size
 */
public record GpsQualityStats(
    int totalPoints,
    int suspectPoints,
    int effectivePoints,
    double meanError,
    double p50,
    double p95,
    Double p99,
    double maxError,
    double jitterDiameter,
    int outlierCount,
    QualityGrade grade
) {}
