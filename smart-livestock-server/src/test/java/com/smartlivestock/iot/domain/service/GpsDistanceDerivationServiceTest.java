package com.smartlivestock.iot.domain.service;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class GpsDistanceDerivationServiceTest {

    private final GpsDistanceDerivationService service = new GpsDistanceDerivationService();

    @Test
    void deriveDistanceMeters_returnsHaversineDistanceForValidSegment() {
        var previous = point("28.000000", "112.000000", "2026-08-31T10:00:00Z");
        var current = point("28.001000", "112.000000", "2026-08-31T10:30:00Z");

        Optional<BigDecimal> result = service.deriveDistanceMeters(previous, current);

        assertThat(result).isPresent();
        assertThat(result.get().doubleValue()).isBetween(105.0, 115.0);
    }

    @Test
    void deriveDistanceMeters_treatsSmallMovementAsJitter() {
        var previous = point("28.000000", "112.000000", "2026-08-31T10:00:00Z");
        var current = point("28.000010", "112.000000", "2026-08-31T10:30:00Z");

        assertThat(service.deriveDistanceMeters(previous, current))
                .contains(new BigDecimal("0.0"));
    }

    @Test
    void deriveDistanceMeters_rejectsImplausibleSpeedAsGpsJump() {
        var previous = point("28.000000", "112.000000", "2026-08-31T10:00:00Z");
        var current = point("29.000000", "112.000000", "2026-08-31T10:00:01Z");

        assertThat(service.deriveDistanceMeters(previous, current))
                .contains(new BigDecimal("0.0"));
    }

    @Test
    void deriveDistanceMeters_ignoresStaleOrReversedPoint() {
        var previous = point("28.000000", "112.000000", "2026-08-31T10:00:00Z");
        var stale = point("28.001000", "112.000000", "2026-08-31T23:00:01Z");
        var reversed = point("28.001000", "112.000000", "2026-08-31T09:59:59Z");

        assertThat(service.deriveDistanceMeters(previous, stale)).isEmpty();
        assertThat(service.deriveDistanceMeters(previous, reversed)).isEmpty();
    }

    private GpsDistanceDerivationService.GpsSegmentPoint point(
            String latitude, String longitude, String recordedAt) {
        return new GpsDistanceDerivationService.GpsSegmentPoint(
                new BigDecimal(latitude), new BigDecimal(longitude), Instant.parse(recordedAt));
    }
}
