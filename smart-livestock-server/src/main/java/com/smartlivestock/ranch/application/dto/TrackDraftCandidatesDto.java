package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.port.dto.TrackerCandidate;

import java.util.List;

/**
 * Response of GET /farms/{farmId}/fences/track-draft/candidates: the
 * farm's tracker devices (sorted by lastFixAt descending) plus the farm's
 * fence quota — the client's only pre-check data source (spec §5.5).
 */
public record TrackDraftCandidatesDto(
        List<TrackerCandidate> devices,
        FenceQuota fenceQuota
) {
    /**
     * Farm fence quota. {@code limit} is null when the tier/license imposes
     * no numeric cap (enterprise / unrestricted gate), meaning "unlimited".
     */
    public record FenceQuota(
            long current,
            Integer limit
    ) {
    }
}
