package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Device operational telemetry log entry (one per report cycle).
 * Stored in device_telemetry_logs table (monthly partition).
 */
public class DeviceTelemetryLog {

    private Long id;
    private Long deviceId;
    private Long tenantId;
    private Integer batteryLevel;
    private Integer rssi;
    private BigDecimal snr;
    private String gatewayId;
    private Integer antiDisassemblyStatus;
    private Integer stepNumber;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Integer accelXRaw;
    private Integer accelYRaw;
    private Integer accelZRaw;
    private BigDecimal accelXG;
    private BigDecimal accelYG;
    private BigDecimal accelZG;
    private BigDecimal accelMagnitudeG;
    private BigDecimal motionIntensity;
    private String activityClass;
    private BigDecimal rollDegrees;
    private BigDecimal pitchDegrees;
    private Instant reportTime;
    private Instant createdAt;

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
