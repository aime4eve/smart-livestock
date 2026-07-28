package com.smartlivestock.iot.domain.port.dto;

/**
 * Aggregated deviation statistics of one LINE test (NIX-68, spec §5.2):
 * shortest distances of all spatially matched gps_logs samples (valid trip
 * segments) to the standard track polyline. No pair-rate dimension (samples
 * need no pairing, D10). {@code tripCount} counts the valid trip segments
 * the samples were merged from.
 */
public record LineQualityStats(
    int sampleCount,
    int tripCount,
    double meanDeviation,
    double p50,
    double p95,
    double maxDeviation,
    double within15mPct,
    double within25mPct,
    double within40mPct
) {}
