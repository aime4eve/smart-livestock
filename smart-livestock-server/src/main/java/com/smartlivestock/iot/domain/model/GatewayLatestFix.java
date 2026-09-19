package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Latest valid GPS fix a device reported through a specific gateway (NIX-219):
 * the basis for the per-gateway "latest distance" figure.
 */
public record GatewayLatestFix(
        String gatewayId,
        Instant reportTime,
        BigDecimal latitude,
        BigDecimal longitude
) {
}
