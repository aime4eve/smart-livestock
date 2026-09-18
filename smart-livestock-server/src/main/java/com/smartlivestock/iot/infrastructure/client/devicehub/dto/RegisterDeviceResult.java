package com.smartlivestock.iot.infrastructure.client.devicehub.dto;

/**
 * Mirrors HKT-DeviceHub DeviceProvisioningService.RegisterResult.
 */
public record RegisterDeviceResult(
        Long id,
        String devEui,
        String project,
        String tbDeviceId,
        String status,
        String result) {
}
