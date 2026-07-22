package com.smartlivestock.iot.domain.port.dto;

/**
 * Computed TRAJECTORY quality statistics, output of {@code TrajectoryPairingService.aggregate}.
 * UNPAIRED points never participate in error statistics.
 *
 * @param totalPoints  imported track points
 * @param filePaired   points whose device coordinate came from the file
 * @param logPaired    points paired from gps_logs
 * @param unpaired     points without a device coordinate within tolerance
 * @param pairRate     (filePaired + logPaired) / totalPoints * 100
 * @param meanError    arithmetic mean of paired-point errors (meters)
 * @param p50          50th percentile error (degrades to maxError when paired < 5)
 * @param p95          95th percentile error (degrades to maxError when paired < 20)
 * @param maxError     maximum paired-point error
 */
public record TrajectoryQualityStats(
    int totalPoints,
    int filePaired,
    int logPaired,
    int unpaired,
    double pairRate,
    double meanError,
    double p50,
    double p95,
    double maxError
) {}
