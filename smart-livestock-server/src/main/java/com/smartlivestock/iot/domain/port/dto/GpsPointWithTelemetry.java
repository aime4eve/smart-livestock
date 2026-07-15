package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * GPS point enriched with telemetry context, input to {@code GpsQualityCalculator}.
 *
 * @param latitude         GPS measured latitude
 * @param longitude        GPS measured longitude
 * @param accuracy         GPS reported accuracy (HDOP-based, meters)
 * @param recordedAt       timestamp of the GPS reading
 * @param stepNumber       telemetry step count; {@code null} = no telemetry match (not suspect)
 * @param motionIntensity  motion intensity from accelerometer telemetry
 * @param activityClass    activity classification (e.g. "stationary", "walking")
 */
public record GpsPointWithTelemetry(
    BigDecimal latitude,
    BigDecimal longitude,
    BigDecimal accuracy,
    Instant recordedAt,
    Integer stepNumber,
    BigDecimal motionIntensity,
    String activityClass
) {}
