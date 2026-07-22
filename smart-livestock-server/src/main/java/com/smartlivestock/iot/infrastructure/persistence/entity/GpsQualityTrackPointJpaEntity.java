package com.smartlivestock.iot.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "gps_quality_track_points")
public class GpsQualityTrackPointJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "test_id", nullable = false)
    private Long testId;

    @Column(name = "sequence_no", nullable = false)
    private Integer sequenceNo;

    @Column(name = "collected_at", nullable = false)
    private Instant collectedAt;

    @Column(name = "rtk_latitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal rtkLatitude;

    @Column(name = "rtk_longitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal rtkLongitude;

    @Column(name = "device_latitude", precision = 10, scale = 7)
    private BigDecimal deviceLatitude;

    @Column(name = "device_longitude", precision = 10, scale = 7)
    private BigDecimal deviceLongitude;

    @Column(name = "match_source", nullable = false, length = 10)
    private String matchSource;

    @Column(name = "matched_gps_log_id")
    private Long matchedGpsLogId;

    @Column(name = "time_diff_seconds")
    private Integer timeDiffSeconds;

    @Column(name = "tolerance_seconds", nullable = false)
    private Integer toleranceSeconds = 60;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

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
    public String getMatchSource() { return matchSource; }
    public void setMatchSource(String matchSource) { this.matchSource = matchSource; }
    public Long getMatchedGpsLogId() { return matchedGpsLogId; }
    public void setMatchedGpsLogId(Long matchedGpsLogId) { this.matchedGpsLogId = matchedGpsLogId; }
    public Integer getTimeDiffSeconds() { return timeDiffSeconds; }
    public void setTimeDiffSeconds(Integer timeDiffSeconds) { this.timeDiffSeconds = timeDiffSeconds; }
    public Integer getToleranceSeconds() { return toleranceSeconds; }
    public void setToleranceSeconds(Integer toleranceSeconds) { this.toleranceSeconds = toleranceSeconds; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
