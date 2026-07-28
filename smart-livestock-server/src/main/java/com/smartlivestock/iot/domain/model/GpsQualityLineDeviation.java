package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Per-point deviation snapshot of one LINE test (NIX-68, spec §6.5, D4):
 * for each gps_logs report in the test window, the shortest distance to the
 * standard track polyline and the index of the nearest segment.
 */
public class GpsQualityLineDeviation {

    private Long id;
    private Long testId;
    private Integer sequenceNo;
    private Instant recordedAt;
    private BigDecimal longitude;
    private BigDecimal latitude;
    private BigDecimal deviationM;
    private Integer segmentNo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public Integer getSequenceNo() { return sequenceNo; }
    public void setSequenceNo(Integer sequenceNo) { this.sequenceNo = sequenceNo; }
    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
    public BigDecimal getDeviationM() { return deviationM; }
    public void setDeviationM(BigDecimal deviationM) { this.deviationM = deviationM; }
    public Integer getSegmentNo() { return segmentNo; }
    public void setSegmentNo(Integer segmentNo) { this.segmentNo = segmentNo; }
}
