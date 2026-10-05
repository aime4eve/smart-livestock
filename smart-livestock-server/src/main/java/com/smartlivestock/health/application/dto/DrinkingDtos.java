package com.smartlivestock.health.application.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * DTOs for the drinking-event marking loop (NIX-256 Task 3, spec §15.2).
 * {@code eventStartAt} is a wall-clock {@code "yyyy-MM-dd HH:mm"} string in
 * Asia/Shanghai; responses expose UTC instants.
 */
public final class DrinkingDtos {

    private DrinkingDtos() {}

    /** PATCH body: {label: "CONFIRMED"|"REJECTED"|"UNLABELED"}. */
    public record DrinkingLabelRequest(String label) {}

    /** POST body: {eventStartAt: "yyyy-MM-dd HH:mm", note?}. */
    public record DrinkingManualRequest(String eventStartAt, String note) {}

    /**
     * POST /api/v1/admin/drinking-recalculate body (NIX-256 Task 4):
     * {deviceId?, from: "yyyy-MM-dd", to: "yyyy-MM-dd"}. The window is a
     * <b>closed date range</b>: from 00:00 → to+1 day 00:00 (Asia/Shanghai).
     * Omitting deviceId recalculates every farm with active capsule
     * bindings (P5).
     */
    public record DrinkingRecalcRequest(Long deviceId, String from, String to) {}

    /**
     * Recalculation summary. {@code scope} is "DEVICE" (single device,
     * {@code farms} null) or "ALL_FARMS" (farm sweep; {@code failedFarms}
     * counts farms whose recalculation threw — the sweep continues past
     * them, mirroring the nightly batch semantics).
     */
    public record DrinkingRecalcResponse(String scope, Integer farms, int devices, int events, int failedFarms) {}

    public record DrinkingEventResponse(
            Long id,
            Long livestockId,
            Long deviceId,
            Instant eventStartAt,
            Instant eventEndAt,
            BigDecimal tempDrop,
            BigDecimal minTemp,
            String source,
            String label,
            BigDecimal confidence,
            String algorithmVersion,
            String note,
            Instant createdAt,
            Instant updatedAt
    ) {}
}
