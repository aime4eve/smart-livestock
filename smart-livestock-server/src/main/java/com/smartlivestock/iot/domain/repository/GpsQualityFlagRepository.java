package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.GpsQualityFlagSummary;

import java.time.Instant;
import java.util.List;

/**
 * Aggregated governance flag counters (NIX-220). Raw frames are never modified;
 * only per-device/rule/day counts are kept here.
 */
public interface GpsQualityFlagRepository {

    /** Upsert-increment the counter for (device, rule, day) and refresh last_reason. */
    void increment(Long deviceId, String ruleName, java.time.LocalDate day, String reason);

    /** Daily totals per rule within [from, to] (by flag day, UTC-based). */
    List<GpsQualityFlagSummary> summarize(Instant from, Instant to);

    /** Per-device totals within [from, to], worst offenders first. */
    List<GpsQualityFlagSummary> summarizeByDevice(Instant from, Instant to);
}
