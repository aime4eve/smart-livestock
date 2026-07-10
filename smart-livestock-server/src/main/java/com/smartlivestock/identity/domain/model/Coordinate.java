package com.smartlivestock.identity.domain.model;

import java.math.BigDecimal;

/**
 * Local coordinate value object for Identity context.
 * Avoids cross-context dependency on Ranch's GpsCoordinate.
 */
public record Coordinate(BigDecimal latitude, BigDecimal longitude) {
    public Coordinate {
        if (latitude == null || longitude == null) {
            throw new IllegalArgumentException("latitude and longitude must not be null");
        }
    }
}
