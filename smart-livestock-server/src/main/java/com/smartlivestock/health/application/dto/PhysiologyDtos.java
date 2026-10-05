package com.smartlivestock.health.application.dto;

import java.time.Instant;
import java.util.List;

/**
 * DTOs for the physiology event stream (NIX-256 Task 1a).
 * Request dates are plain {@code yyyy-MM-dd} strings interpreted in
 * Asia/Shanghai; responses expose UTC instants.
 */
public final class PhysiologyDtos {

    private PhysiologyDtos() {}

    /** POST body: {eventType, occurredAt: "yyyy-MM-dd", note?}. */
    public record PhysiologyEventRequest(String eventType, String occurredAt, String note) {}

    /**
     * PUT body: {occurredAt: "yyyy-MM-dd", note?}. Note semantics (N17):
     * key absent or JSON null keeps the stored note; a present blank value
     * ("", whitespace) clears it to NULL; non-blank replaces it.
     */
    public record PhysiologyEventUpdateRequest(String occurredAt, String note) {}

    public record PhysiologyEventResponse(
            Long id,
            Long livestockId,
            String eventType,
            String source,
            Long refId,
            String note,
            Instant occurredAt,
            Long createdBy,
            Instant createdAt,
            Long updatedBy,
            Instant updatedAt,
            Boolean active
    ) {}

    /**
     * Stage chip projection: LACTATING/DRY derived from CALVING/DRY_OFF
     * milestones; {@code null} when the animal has no stage-defining event.
     */
    public record PhysiologyStageProjection(String type, Instant since) {}

    public record PhysiologyEventListResponse(
            List<PhysiologyEventResponse> items,
            PhysiologyStageProjection stage
    ) {}
}
