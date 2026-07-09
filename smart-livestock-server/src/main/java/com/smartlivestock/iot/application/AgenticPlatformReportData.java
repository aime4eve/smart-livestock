package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.util.AccelerometerConverter;
import lombok.extern.slf4j.Slf4j;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * Parses agentic-middle-platform decodeData (nested JSON string) into a standard readings Map.
 * Also reads top-level report-record fields (rssi, snr, reportGateway).
 */
@Slf4j
public class AgenticPlatformReportData {

    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter[] TIME_FORMATS = {
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"),
            DateTimeFormatter.ISO_INSTANT
    };

    /**
     * Parse reportTime string from platform into Instant.
     */
    public static Instant parseReportTime(String reportTime) {
        if (reportTime == null || reportTime.isBlank()) return Instant.now();
        for (DateTimeFormatter fmt : TIME_FORMATS) {
            try {
                if (fmt == DateTimeFormatter.ISO_INSTANT) {
                    return Instant.parse(reportTime);
                }
                LocalDateTime ldt = LocalDateTime.parse(reportTime, fmt);
                return ldt.atZone(ZoneId.systemDefault()).toInstant();
            } catch (Exception ignored) {}
        }
        log.warn("Could not parse reportTime: {}", reportTime);
        return Instant.now();
    }

    /**
     * Convert a single report record into a standard readings Map (spec §6.2 keys).
     * Reads both top-level fields and nested decodeData.properties.properties.
     */
    public static Map<String, Object> toReadings(ReportRecordPageResp.ReportRecord record) {
        Map<String, Object> readings = new HashMap<>();

        // Top-level fields
        if (record.getRssi() != null) readings.put("rssi", record.getRssi());
        if (record.getSnr() != null) readings.put("snr", record.getSnr());
        if (record.getReportGateway() != null) readings.put("gatewayId", record.getReportGateway());

        // Parse decodeData
        if (record.getDecodeData() != null && !record.getDecodeData().isBlank()) {
            try {
                JsonNode root = objectMapper.readTree(record.getDecodeData());
                JsonNode props = root.path("properties").path("properties");

                putIfPresent(readings, props, "battery");
                putIfPresent(readings, props, "latitude");
                putIfPresent(readings, props, "longitude");
                putIfPresent(readings, props, "stepNumber");
                putIfPresent(readings, props, "workMode");
                putIfPresent(readings, props, "antiDisassemblyStatus");

                // Accelerometer raw values
                Integer accelX = getNullableInt(props, "xAxisDirectionAccelerationValue");
                Integer accelY = getNullableInt(props, "yAxisDirectionAccelerationValue");
                Integer accelZ = getNullableInt(props, "zAxisDirectionAccelerationValue");
                if (accelX != null) readings.put("accelXRaw", accelX);
                if (accelY != null) readings.put("accelYRaw", accelY);
                if (accelZ != null) readings.put("accelZRaw", accelZ);
            } catch (Exception e) {
                log.warn("Failed to parse decodeData for record {}: {}", record.getId(), e.getMessage());
            }
        }

        return readings;
    }

    /**
     * Apply LIS3DH accelerometer conversion (方案 B: data-entry boundary).
     * Converts raw uint16 values to g values + derived metrics, adds them to the readings Map.
     */
    public static void applyAccelerometerConversion(Map<String, Object> readings) {
        Integer axRaw = getInteger(readings, "accelXRaw");
        Integer ayRaw = getInteger(readings, "accelYRaw");
        Integer azRaw = getInteger(readings, "accelZRaw");
        if (axRaw == null || ayRaw == null || azRaw == null) return;

        double axG = AccelerometerConverter.toG(axRaw);
        double ayG = AccelerometerConverter.toG(ayRaw);
        double azG = AccelerometerConverter.toG(azRaw);
        double magG = AccelerometerConverter.magnitudeG(axRaw, ayRaw, azRaw);

        readings.put("accelXG", axG);
        readings.put("accelYG", ayG);
        readings.put("accelZG", azG);
        readings.put("accelMagnitudeG", magG);
        readings.put("motionIntensity", AccelerometerConverter.motionIntensity(axRaw, ayRaw, azRaw));
        readings.put("activityClass", AccelerometerConverter.classifyActivity(magG));
        readings.put("rollDegrees", AccelerometerConverter.rollDegrees(axRaw, ayRaw, azRaw));
        readings.put("pitchDegrees", AccelerometerConverter.pitchDegrees(axRaw, ayRaw, azRaw));
    }

    // --- Helpers ---

    private static void putIfPresent(Map<String, Object> readings, JsonNode props, String key) {
        JsonNode node = props.path(key);
        if (!node.isMissingNode() && !node.isNull()) {
            if (key.equals("latitude") || key.equals("longitude")) {
                readings.put(key, node.decimalValue());
            } else {
                readings.put(key, node.asInt());
            }
        }
    }

    private static Integer getNullableInt(JsonNode props, String key) {
        JsonNode node = props.path(key);
        if (node.isMissingNode() || node.isNull()) return null;
        return node.asInt();
    }

    private static Integer getInteger(Map<String, Object> readings, String key) {
        Object val = readings.get(key);
        if (val == null) return null;
        if (val instanceof Integer i) return i;
        if (val instanceof Number n) return n.intValue();
        return Integer.parseInt(val.toString());
    }
}
