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
