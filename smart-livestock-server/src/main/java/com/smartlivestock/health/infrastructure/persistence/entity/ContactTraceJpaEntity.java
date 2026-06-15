package com.smartlivestock.health.infrastructure.persistence.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "contact_traces")
public class ContactTraceJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "from_livestock_id", nullable = false)
    private Long fromLivestockId;

    @Column(name = "to_livestock_id", nullable = false)
    private Long toLivestockId;

    @Column(name = "proximity_meters", nullable = false, precision = 6, scale = 2)
    private BigDecimal proximityMeters;

    @Column(name = "contact_duration_minutes", nullable = false)
    private Integer contactDurationMinutes;

    @Column(name = "last_contact_at", nullable = false)
    private Instant lastContactAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "disease_type")
    private String diseaseType;

    @Column(name = "marked_at")
    private Instant markedAt;

    @Column(name = "risk_score")
    private Integer riskScore;

    @Column(name = "risk_level")
    private String riskLevel;

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }
    public Long getFromLivestockId() { return fromLivestockId; }
    public void setFromLivestockId(Long fromLivestockId) { this.fromLivestockId = fromLivestockId; }
    public Long getToLivestockId() { return toLivestockId; }
    public void setToLivestockId(Long toLivestockId) { this.toLivestockId = toLivestockId; }
    public BigDecimal getProximityMeters() { return proximityMeters; }
    public void setProximityMeters(BigDecimal proximityMeters) { this.proximityMeters = proximityMeters; }
    public Integer getContactDurationMinutes() { return contactDurationMinutes; }
    public void setContactDurationMinutes(Integer contactDurationMinutes) { this.contactDurationMinutes = contactDurationMinutes; }
    public Instant getLastContactAt() { return lastContactAt; }
    public void setLastContactAt(Instant lastContactAt) { this.lastContactAt = lastContactAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public String getDiseaseType() { return diseaseType; }
    public void setDiseaseType(String diseaseType) { this.diseaseType = diseaseType; }
    public Instant getMarkedAt() { return markedAt; }
    public void setMarkedAt(Instant markedAt) { this.markedAt = markedAt; }
    public Integer getRiskScore() { return riskScore; }
    public void setRiskScore(Integer riskScore) { this.riskScore = riskScore; }
    public String getRiskLevel() { return riskLevel; }
    public void setRiskLevel(String riskLevel) { this.riskLevel = riskLevel; }
}
