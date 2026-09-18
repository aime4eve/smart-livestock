package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Daily roaming-radius aggregate of one device (NIX-219 F6): max/mean
 * distance to the receiving registered gateway over one calendar day.
 */
public record LivestockRoamDaily(
        Long deviceId,
        LocalDate roamDay,
        BigDecimal maxDistanceM,
        BigDecimal meanDistanceM,
        Integer frameCount) {
}
