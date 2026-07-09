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
@Table(name = "device_telemetry_logs")
public class DeviceTelemetryLogJpaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "rssi")
    private Integer rssi;

    @Column(name = "snr")
    private BigDecimal snr;

    @Column(name = "gateway_id", length = 128)
    private String gatewayId;

    @Column(name = "anti_disassembly_status")
    private Integer antiDisassemblyStatus;

    @Column(name = "step_number")
    private Integer stepNumber;

    @Column(name = "latitude")
    private BigDecimal latitude;

    @Column(name = "longitude")
    private BigDecimal longitude;

    @Column(name = "accel_x_raw")
    private Integer accelXRaw;

    @Column(name = "accel_y_raw")
    private Integer accelYRaw;

    @Column(name = "accel_z_raw")
    private Integer accelZRaw;

    @Column(name = "accel_x_g")
    private BigDecimal accelXG;

    @Column(name = "accel_y_g")
    private BigDecimal accelYG;

    @Column(name = "accel_z_g")
    private BigDecimal accelZG;

    @Column(name = "accel_magnitude_g")
    private BigDecimal accelMagnitudeG;

    @Column(name = "motion_intensity")
    private BigDecimal motionIntensity;

    @Column(name = "activity_class", length = 10)
    private String activityClass;

    @Column(name = "roll_degrees")
    private BigDecimal rollDegrees;

    @Column(name = "pitch_degrees")
    private BigDecimal pitchDegrees;

    @Column(name = "report_time", nullable = false)
    private Instant reportTime;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public Integer getBatteryLevel() { return batteryLevel; }
    public void setBatteryLevel(Integer batteryLevel) { this.batteryLevel = batteryLevel; }

    public Integer getRssi() { return rssi; }
    public void setRssi(Integer rssi) { this.rssi = rssi; }

    public BigDecimal getSnr() { return snr; }
    public void setSnr(BigDecimal snr) { this.snr = snr; }

    public String getGatewayId() { return gatewayId; }
    public void setGatewayId(String gatewayId) { this.gatewayId = gatewayId; }

    public Integer getAntiDisassemblyStatus() { return antiDisassemblyStatus; }
    public void setAntiDisassemblyStatus(Integer antiDisassemblyStatus) { this.antiDisassemblyStatus = antiDisassemblyStatus; }

    public Integer getStepNumber() { return stepNumber; }
    public void setStepNumber(Integer stepNumber) { this.stepNumber = stepNumber; }

    public BigDecimal getLatitude() { return latitude; }
    public void setLatitude(BigDecimal latitude) { this.latitude = latitude; }

    public BigDecimal getLongitude() { return longitude; }
    public void setLongitude(BigDecimal longitude) { this.longitude = longitude; }

    public Integer getAccelXRaw() { return accelXRaw; }
    public void setAccelXRaw(Integer accelXRaw) { this.accelXRaw = accelXRaw; }

    public Integer getAccelYRaw() { return accelYRaw; }
    public void setAccelYRaw(Integer accelYRaw) { this.accelYRaw = accelYRaw; }

    public Integer getAccelZRaw() { return accelZRaw; }
    public void setAccelZRaw(Integer accelZRaw) { this.accelZRaw = accelZRaw; }

    public BigDecimal getAccelXG() { return accelXG; }
    public void setAccelXG(BigDecimal accelXG) { this.accelXG = accelXG; }

    public BigDecimal getAccelYG() { return accelYG; }
    public void setAccelYG(BigDecimal accelYG) { this.accelYG = accelYG; }

    public BigDecimal getAccelZG() { return accelZG; }
    public void setAccelZG(BigDecimal accelZG) { this.accelZG = accelZG; }

    public BigDecimal getAccelMagnitudeG() { return accelMagnitudeG; }
    public void setAccelMagnitudeG(BigDecimal accelMagnitudeG) { this.accelMagnitudeG = accelMagnitudeG; }

    public BigDecimal getMotionIntensity() { return motionIntensity; }
    public void setMotionIntensity(BigDecimal motionIntensity) { this.motionIntensity = motionIntensity; }

    public String getActivityClass() { return activityClass; }
    public void setActivityClass(String activityClass) { this.activityClass = activityClass; }

    public BigDecimal getRollDegrees() { return rollDegrees; }
    public void setRollDegrees(BigDecimal rollDegrees) { this.rollDegrees = rollDegrees; }

    public BigDecimal getPitchDegrees() { return pitchDegrees; }
    public void setPitchDegrees(BigDecimal pitchDegrees) { this.pitchDegrees = pitchDegrees; }

    public Instant getReportTime() { return reportTime; }
    public void setReportTime(Instant reportTime) { this.reportTime = reportTime; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
