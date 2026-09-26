package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "livestock_location_snapshots")
public class LivestockLocationSnapshotJpaEntity {

    @Id
    @Column(name = "livestock_id")
    private Long livestockId;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "latitude", nullable = false)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false)
    private BigDecimal longitude;

    @Column(name = "accuracy")
    private BigDecimal accuracy;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "source", nullable = false, length = 32)
    private String source;

    @Column(name = "position_revision", nullable = false)
    private Long positionRevision;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Long getLivestockId() { return livestockId; }
    public void setLivestockId(Long livestockId) { this.livestockId = livestockId; }
    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }
    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }
    public BigDecimal getAccuracy() { return accuracy; }
    public void setAccuracy(BigDecimal accuracy) { this.accuracy = accuracy; }
    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public Long getPositionRevision() { return positionRevision; }
    public void setPositionRevision(Long positionRevision) { this.positionRevision = positionRevision; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
