package com.smartlivestock.iot.infrastructure.client.devicehub.dto;

import java.util.Map;

/**
 * Mirrors HKT-DeviceHub interfaces/dto/RegisterDeviceRequest.
 */
public record RegisterDeviceRequest(
        String devEui,
        String project,
        String externalRef,
        Map<String, Object> capabilities) {
}
