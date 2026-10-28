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

    // Columns are DOUBLE PRECISION in the migration (V20260927090000);
    // BigDecimal would map to numeric(38,2) and fail schema validation.
    @Column(name = "latitude", nullable = false)
    private Double latitude;

    @Column(name = "longitude", nullable = false)
    private Double longitude;

    @Column(name = "accuracy")
    private Double accuracy;

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
    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }
    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }
    public Double getAccuracy() { return accuracy; }
    public void setAccuracy(Double accuracy) { this.accuracy = accuracy; }
    public Instant getRecordedAt() { return recordedAt; }
    public void setRecordedAt(Instant recordedAt) { this.recordedAt = recordedAt; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public Long getPositionRevision() { return positionRevision; }
    public void setPositionRevision(Long positionRevision) { this.positionRevision = positionRevision; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
