package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;

/**
 * One point of a standard track line (NIX-68, spec §6.3). No timestamp:
 * handset metadata is not trusted, only the geometry is kept (D6).
 * Cleaning = consecutive-duplicate removal only (D7).
 */
public class StandardTrackLinePoint {

    private Long id;
    private Long lineId;
    private Integer sequenceNo;
    private BigDecimal longitude;
    private BigDecimal latitude;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getLineId() { return lineId; }
    public void setLineId(Long lineId) { this.lineId = lineId; }
    public Integer getSequenceNo() { return sequenceNo; }
    public void setSequenceNo(Integer sequenceNo) { this.sequenceNo = sequenceNo; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
}
