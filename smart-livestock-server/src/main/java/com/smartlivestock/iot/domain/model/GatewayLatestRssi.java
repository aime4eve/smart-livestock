package com.smartlivestock.iot.domain.model;

import java.time.Instant;

/**
 * Latest frame (with RSSI) a device reported through a gateway, regardless of
 * GPS validity — the input for plan-B inferred distances on no-GPS gateways.
 */
public record GatewayLatestRssi(String gatewayId, Instant reportTime, int rssi) {
}
