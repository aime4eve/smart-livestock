package com.smartlivestock.iot.domain.service;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.util.AccelerometerConverter;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * Decoded cattle/sheep tracker uplink frame (NIX-79).
 * <p>
 * Holds the business-relevant TLV fields of one frame; types that are only
 * consumed for framing (version, device id, temperature/humidity, sync,
 * run-mode config, power/work/fault mode, ACK) are parsed but not kept.
 * <p>
 * Field semantics follow the firmware packing protocol
 * ({@code docs/protocols/LoRaWAN 牛羊追踪器上行 Payload 解析协议定义.md}):
 * <ul>
 *   <li>{@code stepCount} is the per-report-cycle step count (firmware clears
 *       its counter after each package) — mapped directly, never to
 *       {@code stepNumber} (spec §4.5)</li>
 *   <li>latitude/longitude use the special u32 encoding (bit31 = sign) ÷ 1e6</li>
 *   <li>accelerometer values are signed s16, passed through as-is</li>
 * </ul>
 */
public class DecodedTrackerFrame {

    private final int specialType;
    private final int packSyncNumber;
    private Integer battery;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private Integer stepCount;
    private Integer accelXRaw;
    private Integer accelYRaw;
    private Integer accelZRaw;
    private Integer antiDisassemblyStatus;

    DecodedTrackerFrame(int specialType, int packSyncNumber) {
        this.specialType = specialType;
        this.packSyncNumber = packSyncNumber;
    }

    public int getSpecialType() { return specialType; }
    public int getPackSyncNumber() { return packSyncNumber; }

    public Integer getBattery() { return battery; }
    void setBattery(Integer battery) { this.battery = battery; }

    public BigDecimal getLatitude() { return latitude; }
    void setLatitude(BigDecimal latitude) { this.latitude = latitude; }

    public BigDecimal getLongitude() { return longitude; }
    void setLongitude(BigDecimal longitude) { this.longitude = longitude; }

    public Integer getStepCount() { return stepCount; }
    void setStepCount(Integer stepCount) { this.stepCount = stepCount; }

    public Integer getAccelXRaw() { return accelXRaw; }
    void setAccelXRaw(Integer accelXRaw) { this.accelXRaw = accelXRaw; }

    public Integer getAccelYRaw() { return accelYRaw; }
    void setAccelYRaw(Integer accelYRaw) { this.accelYRaw = accelYRaw; }

    public Integer getAccelZRaw() { return accelZRaw; }
    void setAccelZRaw(Integer accelZRaw) { this.accelZRaw = accelZRaw; }

    public Integer getAntiDisassemblyStatus() { return antiDisassemblyStatus; }
    void setAntiDisassemblyStatus(Integer antiDisassemblyStatus) { this.antiDisassemblyStatus = antiDisassemblyStatus; }

    /**
     * Convert to the standard ingest readings map (same keys and numeric
     * conventions as the agentic-platform chain). Accelerometer g-values and
     * derived metrics reuse {@link AccelerometerConverter} so both pipelines
     * stay numerically identical.
     */
    public Map<String, Object> toReadings() {
        Map<String, Object> readings = new HashMap<>();
        if (battery != null) readings.put("battery", battery);
        if (latitude != null) readings.put("latitude", latitude);
        if (longitude != null) readings.put("longitude", longitude);
        // Per-cycle steps go straight to stepCount; never write stepNumber
        // (platform cumulative semantics must not be mixed in, spec §4.5).
        if (stepCount != null) readings.put("stepCount", stepCount);
        if (antiDisassemblyStatus != null) readings.put("antiDisassemblyStatus", antiDisassemblyStatus);
        if (accelXRaw != null) readings.put("accelXRaw", accelXRaw);
        if (accelYRaw != null) readings.put("accelYRaw", accelYRaw);
        if (accelZRaw != null) readings.put("accelZRaw", accelZRaw);

        if (accelXRaw != null && accelYRaw != null && accelZRaw != null) {
            double magG = AccelerometerConverter.magnitudeG(accelXRaw, accelYRaw, accelZRaw);
            readings.put("accelXG", AccelerometerConverter.toG(accelXRaw));
            readings.put("accelYG", AccelerometerConverter.toG(accelYRaw));
            readings.put("accelZG", AccelerometerConverter.toG(accelZRaw));
            readings.put("accelMagnitudeG", magG);
            readings.put("motionIntensity",
                    AccelerometerConverter.motionIntensity(accelXRaw, accelYRaw, accelZRaw));
            readings.put("activityClass", AccelerometerConverter.classifyActivity(magG));
            readings.put("rollDegrees",
                    AccelerometerConverter.rollDegrees(accelXRaw, accelYRaw, accelZRaw));
            readings.put("pitchDegrees",
                    AccelerometerConverter.pitchDegrees(accelXRaw, accelYRaw, accelZRaw));
        }
        return readings;
    }
}
