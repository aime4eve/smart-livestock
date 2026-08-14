package com.smartlivestock.iot.domain.service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Decoded rumen capsule standard TLV uplink frame.
 */
public class DecodedRumenFrame {

    private final int specialType;
    private final int packSyncNumber;
    private final List<BigDecimal> temperatures = new ArrayList<>();
    private Integer batteryPercent;
    private Integer batteryVoltage;
    private Long gastricMotility;
    private Integer accelXRaw;
    private Integer accelYRaw;
    private Integer accelZRaw;
    private Integer reportIntervalMinutes;

    DecodedRumenFrame(int specialType, int packSyncNumber) {
        this.specialType = specialType;
        this.packSyncNumber = packSyncNumber;
    }

    public int getSpecialType() { return specialType; }
    public int getPackSyncNumber() { return packSyncNumber; }

    List<BigDecimal> temperatures() { return temperatures; }
    void setBatteryPercent(Integer batteryPercent) { this.batteryPercent = batteryPercent; }
    void setBatteryVoltage(Integer batteryVoltage) { this.batteryVoltage = batteryVoltage; }
    void setGastricMotility(Long gastricMotility) { this.gastricMotility = gastricMotility; }
    void setAccelXRaw(Integer accelXRaw) { this.accelXRaw = accelXRaw; }
    void setAccelYRaw(Integer accelYRaw) { this.accelYRaw = accelYRaw; }
    void setAccelZRaw(Integer accelZRaw) { this.accelZRaw = accelZRaw; }
    void setReportIntervalMinutes(Integer reportIntervalMinutes) {
        this.reportIntervalMinutes = reportIntervalMinutes;
    }

    public Map<String, Object> toReadings() {
        Map<String, Object> readings = new HashMap<>();
        readings.put("temperatures", List.copyOf(temperatures));
        if (batteryPercent != null) readings.put("battery", batteryPercent);
        if (batteryVoltage != null) {
            readings.put("batteryVoltage", batteryVoltage);
            readings.put("battery", batteryPercent(batteryVoltage));
        }
        if (gastricMotility != null) readings.put("gastricMotility", gastricMotility);
        if (accelXRaw != null) readings.put("accelXRaw", accelXRaw);
        if (accelYRaw != null) readings.put("accelYRaw", accelYRaw);
        if (accelZRaw != null) readings.put("accelZRaw", accelZRaw);
        if (reportIntervalMinutes != null) {
            readings.put("reportIntervalMinutes", reportIntervalMinutes);
        }
        return readings;
    }

    private static int batteryPercent(int voltage) {
        if (voltage >= 3100) return 100;
        if (voltage > 2500) return (voltage - 2500) * 100 / 600;
        return 0;
    }
}
