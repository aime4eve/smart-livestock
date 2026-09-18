package com.smartlivestock.iot.infrastructure.client.devicehub.dto;

import java.util.List;
import java.util.Map;

/**
 * Mirrors HKT-DeviceHub DeviceProvisioningService.ReconcileReport / ReconcileRow.
 */
public record ReconcileReport(
        String project,
        List<ReconcileRow> rows,
        Map<String, Long> counts) {

    public record ReconcileRow(
            String devEui,
            String tbDeviceId,
            String status,
            List<String> differenceCodes) {
    }
}
