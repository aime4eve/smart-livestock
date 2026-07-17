package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;

/**
 * Ordered RTK route point, input to {@code DynamicQualityCalculator}.
 *
 * @param latitude    RTK ground-truth latitude
 * @param longitude   RTK ground-truth longitude
 * @param sequenceNo  1-based traversal order within the route
 */
public record RoutePoint(
    BigDecimal latitude,
    BigDecimal longitude,
    int sequenceNo
) {}
