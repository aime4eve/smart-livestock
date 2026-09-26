package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "farm_signal_revisions")
public class FarmSignalRevisionJpaEntity {

    @Id
    @Column(name = "farm_id")
    private Long farmId;

    @Column(name = "status_revision", nullable = false)
    private Long statusRevision;

    @Column(name = "position_revision", nullable = false)
    private Long positionRevision;

    @Column(name = "fence_geometry_revision", nullable = false)
    private Long fenceGeometryRevision;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }
    public Long getStatusRevision() { return statusRevision; }
    public void setStatusRevision(Long statusRevision) { this.statusRevision = statusRevision; }
    public Long getPositionRevision() { return positionRevision; }
    public void setPositionRevision(Long positionRevision) { this.positionRevision = positionRevision; }
    public Long getFenceGeometryRevision() { return fenceGeometryRevision; }
    public void setFenceGeometryRevision(Long fenceGeometryRevision) { this.fenceGeometryRevision = fenceGeometryRevision; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
