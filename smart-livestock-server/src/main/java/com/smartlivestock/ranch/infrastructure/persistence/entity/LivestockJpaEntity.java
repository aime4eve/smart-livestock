package com.smartlivestock.ranch.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "livestock")
public class LivestockJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_code", nullable = false, length = 50)
    private String livestockCode;

    @Column(name = "breed", length = 50)
    private String breed;

    @Column(name = "gender", length = 10)
    private String gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "weight", precision = 7, scale = 2)
    private BigDecimal weight;

    @Column(name = "health_status", nullable = false, length = 20)
    private String healthStatus;

    @Column(name = "last_latitude", precision = 10, scale = 7)
    private BigDecimal lastLatitude;

    @Column(name = "last_longitude", precision = 10, scale = 7)
    private BigDecimal lastLongitude;

    @Column(name = "last_position_at")
    private Instant lastPositionAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getFarmId() { return farmId; }
    public void setFarmId(Long farmId) { this.farmId = farmId; }

    public String getLivestockCode() { return livestockCode; }
    public void setLivestockCode(String livestockCode) { this.livestockCode = livestockCode; }

    public String getBreed() { return breed; }
    public void setBreed(String breed) { this.breed = breed; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public LocalDate getBirthDate() { return birthDate; }
    public void setBirthDate(LocalDate birthDate) { this.birthDate = birthDate; }

    public BigDecimal getWeight() { return weight; }
    public void setWeight(BigDecimal weight) { this.weight = weight; }

    public String getHealthStatus() { return healthStatus; }
    public void setHealthStatus(String healthStatus) { this.healthStatus = healthStatus; }

    public BigDecimal getLastLatitude() { return lastLatitude; }
    public void setLastLatitude(BigDecimal lastLatitude) { this.lastLatitude = lastLatitude; }

    public BigDecimal getLastLongitude() { return lastLongitude; }
    public void setLastLongitude(BigDecimal lastLongitude) { this.lastLongitude = lastLongitude; }

    public Instant getLastPositionAt() { return lastPositionAt; }
    public void setLastPositionAt(Instant lastPositionAt) { this.lastPositionAt = lastPositionAt; }

    public Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
