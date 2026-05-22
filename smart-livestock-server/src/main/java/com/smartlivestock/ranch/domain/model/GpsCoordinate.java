package com.smartlivestock.ranch.domain.model;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.util.Objects;

/**
 * Immutable GPS coordinate value object using BigDecimal for precision.
 *
 * @param latitude  north-south position (-90 to 90)
 * @param longitude east-west position (-180 to 180)
 */
public record GpsCoordinate(
        @JsonProperty("lat") BigDecimal latitude,
        @JsonProperty("lng") BigDecimal longitude) {

    public GpsCoordinate {
        Objects.requireNonNull(latitude, "latitude must not be null");
        Objects.requireNonNull(longitude, "longitude must not be null");
    }

    /**
     * Secondary constructor accepting String values for convenient construction.
     */
    public GpsCoordinate(String latitude, String longitude) {
        this(new BigDecimal(latitude), new BigDecimal(longitude));
    }
}
