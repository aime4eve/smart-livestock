package com.smartlivestock.shared.domain;

import java.util.List;

/**
 * Page of telemetry readings for the Open API telemetry endpoints (NIX-323).
 * Each telemetry type paginates independently with its own total.
 */
public record TelemetryPage<T>(List<T> items, int page, int pageSize, long total) {

    public static <T> TelemetryPage<T> empty(int page, int pageSize) {
        return new TelemetryPage<>(List.of(), page, pageSize, 0L);
    }
}
