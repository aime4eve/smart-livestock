package com.smartlivestock.iot.interfaces.admin.dto;

import java.time.Instant;
import java.util.List;

/**
 * Cross-device LINE comparison (NIX-68, spec §7.6): statistical rows plus the
 * standard track polyline. A device's own track points are only included when
 * requested via the deviceCode parameter (lazy per-device loading).
 */
public class LineComparisonDto {

    private List<LineTrackPointDto> trackLine;
    private List<Row> rows;
    private List<LineTrackPointDto> deviceTrack;

    public record Row(
        Long testId,
        String deviceCode,
        int sampleCount,
        double mean,
        double p50,
        double p95,
        double max,
        double within15mPct,
        double within25mPct,
        double within40mPct,
        String grade,
        Instant startedAt,
        Instant endedAt
    ) {}

    public List<LineTrackPointDto> getTrackLine() { return trackLine; }
    public void setTrackLine(List<LineTrackPointDto> trackLine) { this.trackLine = trackLine; }
    public List<Row> getRows() { return rows; }
    public void setRows(List<Row> rows) { this.rows = rows; }
    public List<LineTrackPointDto> getDeviceTrack() { return deviceTrack; }
    public void setDeviceTrack(List<LineTrackPointDto> deviceTrack) { this.deviceTrack = deviceTrack; }
}
