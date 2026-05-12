package com.smartlivestock.ranch.domain.model;

import com.smartlivestock.shared.domain.AggregateRoot;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Livestock aggregate root representing an animal on a farm.
 */
public class Livestock extends AggregateRoot {

    private Long farmId;
    private String livestockCode;
    private String breed;
    private String gender;
    private LocalDate birthDate;
    private BigDecimal weight;
    private HealthStatus healthStatus;
    private BigDecimal lastLatitude;
    private BigDecimal lastLongitude;
    private Instant lastPositionAt;

    public Livestock() {
        this.healthStatus = HealthStatus.HEALTHY;
    }

    public Livestock(Long farmId, String livestockCode, String breed,
                     String gender, LocalDate birthDate, BigDecimal weight) {
        this.farmId = farmId;
        this.livestockCode = livestockCode;
        this.breed = breed;
        this.gender = gender;
        this.birthDate = birthDate;
        this.weight = weight;
        this.healthStatus = HealthStatus.HEALTHY;
    }

    /**
     * Update the last known GPS position of this livestock.
     */
    public void updatePosition(BigDecimal latitude, BigDecimal longitude) {
        this.lastLatitude = latitude;
        this.lastLongitude = longitude;
        this.lastPositionAt = Instant.now();
    }

    public void markWarning() {
        this.healthStatus = HealthStatus.WARNING;
    }

    public void markCritical() {
        this.healthStatus = HealthStatus.CRITICAL;
    }

    public void markHealthy() {
        this.healthStatus = HealthStatus.HEALTHY;
    }

    // --- Getters and Setters ---

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

    public HealthStatus getHealthStatus() { return healthStatus; }
    public void setHealthStatus(HealthStatus healthStatus) { this.healthStatus = healthStatus; }

    public BigDecimal getLastLatitude() { return lastLatitude; }

    public BigDecimal getLastLongitude() { return lastLongitude; }

    public Instant getLastPositionAt() { return lastPositionAt; }

    /**
     * Reconstitute last known position from persistence.
     */
    public void reconstitutePosition(BigDecimal latitude, BigDecimal longitude, Instant positionAt) {
        this.lastLatitude = latitude;
        this.lastLongitude = longitude;
        this.lastPositionAt = positionAt;
    }
}
