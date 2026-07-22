package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * One imported RTK track point of a TRAJECTORY test, holding the pairing
 * snapshot decided at import time (spec D2):
 * <ul>
 *   <li>{@link TrackMatchSource#FILE} — device coordinate from the file</li>
 *   <li>{@link TrackMatchSource#GPS_LOG} — device coordinate paired from gps_logs</li>
 *   <li>{@link TrackMatchSource#UNPAIRED} — no report within tolerance</li>
 * </ul>
 * Reports read these snapshots only; gps_logs is never re-queried.
 */
public class GpsQualityTrackPoint {

    private Long id;
    private Long testId;
    private Integer sequenceNo;
    private Instant collectedAt;
    private BigDecimal rtkLatitude;
    private BigDecimal rtkLongitude;
    private BigDecimal deviceLatitude;
    private BigDecimal deviceLongitude;
    private TrackMatchSource matchSource;
    private Long matchedGpsLogId;
    private Integer timeDiffSeconds;
    private Integer toleranceSeconds;
    private Instant createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public Integer getSequenceNo() { return sequenceNo; }
    public void setSequenceNo(Integer sequenceNo) { this.sequenceNo = sequenceNo; }
    public Instant getCollectedAt() { return collectedAt; }
    public void setCollectedAt(Instant collectedAt) { this.collectedAt = collectedAt; }
    public BigDecimal getRtkLatitude() { return rtkLatitude; }
    public void setRtkLatitude(BigDecimal rtkLatitude) { this.rtkLatitude = rtkLatitude; }
    public BigDecimal getRtkLongitude() { return rtkLongitude; }
    public void setRtkLongitude(BigDecimal rtkLongitude) { this.rtkLongitude = rtkLongitude; }
    public BigDecimal getDeviceLatitude() { return deviceLatitude; }
    public void setDeviceLatitude(BigDecimal deviceLatitude) { this.deviceLatitude = deviceLatitude; }
    public BigDecimal getDeviceLongitude() { return deviceLongitude; }
    public void setDeviceLongitude(BigDecimal deviceLongitude) { this.deviceLongitude = deviceLongitude; }
    public TrackMatchSource getMatchSource() { return matchSource; }
    public void setMatchSource(TrackMatchSource matchSource) { this.matchSource = matchSource; }
    public Long getMatchedGpsLogId() { return matchedGpsLogId; }
    public void setMatchedGpsLogId(Long matchedGpsLogId) { this.matchedGpsLogId = matchedGpsLogId; }
    public Integer getTimeDiffSeconds() { return timeDiffSeconds; }
    public void setTimeDiffSeconds(Integer timeDiffSeconds) { this.timeDiffSeconds = timeDiffSeconds; }
    public Integer getToleranceSeconds() { return toleranceSeconds; }
    public void setToleranceSeconds(Integer toleranceSeconds) { this.toleranceSeconds = toleranceSeconds; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
