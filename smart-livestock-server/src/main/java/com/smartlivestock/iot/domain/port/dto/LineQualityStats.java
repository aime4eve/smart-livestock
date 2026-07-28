package com.smartlivestock.iot.domain.port.dto;

/**
 * Aggregated deviation statistics of one LINE test (NIX-68, spec §5.2):
 * shortest distances of all gps_logs samples in the window to the standard
 * track polyline. No pair-rate dimension (samples need no pairing, D10).
 */
public record LineQualityStats(
    int sampleCount,
    double meanDeviation,
    double p50,
    double p95,
    double maxDeviation,
    double within15mPct,
    double within25mPct,
    double within40mPct
) {}
