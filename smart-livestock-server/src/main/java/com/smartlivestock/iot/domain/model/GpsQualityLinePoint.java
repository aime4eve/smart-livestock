package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;

/**
 * Point-list snapshot of the standard track line used by one LINE test
 * (NIX-68, spec §6.4, D4): taken at test creation so later candidate
 * deletion or re-import never changes historical reports.
 */
public class GpsQualityLinePoint {

    private Long id;
    private Long testId;
    private Integer sequenceNo;
    private BigDecimal longitude;
    private BigDecimal latitude;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTestId() { return testId; }
    public void setTestId(Long testId) { this.testId = testId; }
    public Integer getSequenceNo() { return sequenceNo; }
    public void setSequenceNo(Integer sequenceNo) { this.sequenceNo = sequenceNo; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
}
