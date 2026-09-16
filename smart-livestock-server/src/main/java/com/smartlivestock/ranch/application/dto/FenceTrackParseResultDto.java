package com.smartlivestock.ranch.application.dto;

import java.util.List;

/**
 * Parse-preview result for a GPX track targeted at fence creation (NIX-213).
 *
 * <p>Mirrors the gps-quality track-lines parse contract (statistics + preview
 * points), plus {@link #trackPoints()} — the cleaned point list the client
 * feeds into its local envelope pipeline. Stateless: nothing is persisted;
 * the only fence write path remains POST /fences.</p>
 */
public record FenceTrackParseResultDto(
        String defaultName,
        int rawPointCount,
        int pointCount,
        int removedDuplicates,
        int invalidPoints,
        double lengthMeters,
        double startLat,
        double startLng,
        double endLat,
        double endLng,
        String metadataWarning,
        List<TrackPointDto> previewPoints,
        List<TrackPointDto> trackPoints) {

    /** One cleaned track point. {@code sequenceNo} is 1-based within {@link #trackPoints()}. */
    public record TrackPointDto(int sequenceNo, double lat, double lng) {
    }
}
