package com.smartlivestock.iot.domain.service;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

/**
 * Derives one activity segment distance from consecutive valid GPS fixes.
 */
@Service
public class GpsDistanceDerivationService {

    private static final BigDecimal JITTER_METERS = new BigDecimal("5.0");
    private static final double MAX_SPEED_METERS_PER_SECOND = 15.0;
    private static final Duration MAX_SEGMENT_INTERVAL = Duration.ofHours(12);

    public record GpsSegmentPoint(
            BigDecimal latitude, BigDecimal longitude, Instant recordedAt) {}

    public Optional<BigDecimal> deriveDistanceMeters(
            GpsSegmentPoint previous, GpsSegmentPoint current) {
        if (!isValid(previous) || !isValid(current)
                || !current.recordedAt().isAfter(previous.recordedAt())) {
            return Optional.empty();
        }

        Duration elapsed = Duration.between(previous.recordedAt(), current.recordedAt());
        if (elapsed.compareTo(MAX_SEGMENT_INTERVAL) > 0) {
            return Optional.empty();
        }

        double distance = TrackLineCalculator.haversineMeters(
                previous.latitude().doubleValue(),
                previous.longitude().doubleValue(),
                current.latitude().doubleValue(),
                current.longitude().doubleValue());
        if (distance < JITTER_METERS.doubleValue()
                || distance / elapsed.toSeconds() > MAX_SPEED_METERS_PER_SECOND) {
            return Optional.of(BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP));
        }

        return Optional.of(BigDecimal.valueOf(distance).setScale(1, RoundingMode.HALF_UP));
    }

    private boolean isValid(GpsSegmentPoint point) {
        return point != null
                && point.latitude() != null
                && point.longitude() != null
                && point.recordedAt() != null
                && point.latitude().abs().compareTo(BigDecimal.valueOf(90)) <= 0
                && point.longitude().abs().compareTo(BigDecimal.valueOf(180)) <= 0
                && (point.latitude().compareTo(BigDecimal.ZERO) != 0
                || point.longitude().compareTo(BigDecimal.ZERO) != 0);
    }
}
