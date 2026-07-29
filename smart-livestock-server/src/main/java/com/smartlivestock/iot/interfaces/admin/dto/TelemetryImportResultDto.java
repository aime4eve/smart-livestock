package com.smartlivestock.iot.interfaces.admin.dto;

/**
 * Telemetry import execution result (NIX-79, spec §4.1).
 */
public record TelemetryImportResultDto(
        int telemetryCreated,
        int gpsCreated,
        int duplicateSkipped,
        int skippedRows,
        int invalidRows,
        int failedRows,
        String devEui,
        String deviceCode
) {}
