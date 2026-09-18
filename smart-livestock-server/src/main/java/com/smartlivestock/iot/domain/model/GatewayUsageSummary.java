package com.smartlivestock.iot.domain.model;

import java.time.Instant;

/**
 * Gateway usage aggregation row for gateway discovery (NIX-219):
 * which gateways a set of devices actually talked to and when last.
 * avgRssi (nullable) feeds the link-tier dot in the discovery list.
 */
public record GatewayUsageSummary(String gatewayId, Instant lastSeen, long frames, Double avgRssi) {
}
