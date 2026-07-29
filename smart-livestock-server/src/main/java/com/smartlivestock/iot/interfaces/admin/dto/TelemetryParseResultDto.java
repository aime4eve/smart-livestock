package com.smartlivestock.iot.interfaces.admin.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Telemetry import parse preview (NIX-79, spec §4.1). Zero persistence.
 * <p>
 * Row-level {@code error} carries an i18n message key (never a translated
 * string); the frontend maps keys to localized text.
 */
public record TelemetryParseResultDto(
        int totalRows,
        int uplinkRows,
        int decodableRows,
        int importableRows,
        int gpsPointRows,
        int duplicateRows,
        int skippedRows,
        int invalidRows,
        DeviceMatchDto device,
        List<Row> rows
) {
    /** Device match outcome; when matched=false, error holds the reason key. */
    public record DeviceMatchDto(boolean matched, String devEui, String deviceCode,
                                 String deviceType, String livestockName, String farmName,
                                 String error) {}

    /**
     * One file row preview.
     *
     * @param status IMPORTABLE / DUPLICATE / SKIPPED_DOWNLINK / SKIPPED_UNSUPPORTED / INVALID
     * @param error  i18n key for INVALID rows, otherwise null
     */
    public record Row(int rowNo, String frameCounter, Instant recordTime,
                      Integer battery, BigDecimal latitude, BigDecimal longitude, Integer stepCount,
                      String status, String error) {}
}
