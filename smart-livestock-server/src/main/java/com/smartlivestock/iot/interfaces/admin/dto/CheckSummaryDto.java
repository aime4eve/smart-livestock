package com.smartlivestock.iot.interfaces.admin.dto;

import java.time.Instant;
import java.util.List;

/**
 * Unified latest-check summary for one device (NIX-68, spec §7.5): the most
 * recent test of each type (STATIC / DYNAMIC / TRAJECTORY / LINE). Types
 * without any test are simply absent from the list.
 */
public class CheckSummaryDto {

    private List<Item> items;

    /**
     * @param keyMetric type-specific headline metric, e.g. "p95 12.3m" for
     *                  STATIC/DYNAMIC, "mean 8.2m · pair 95%" for TRAJECTORY,
     *                  "mean 6.1m · p95 12.3m" for LINE
     */
    public record Item(
        String checkType,
        Long testId,
        Instant endedAt,
        String grade,
        String keyMetric
    ) {}

    public List<Item> getItems() { return items; }
    public void setItems(List<Item> items) { this.items = items; }
}
