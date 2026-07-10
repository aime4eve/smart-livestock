package com.smartlivestock.ranch.domain.port.dto;

/**
 * Brief device info for livestock list enrichment.
 */
public record DeviceBrief(
        Long deviceId,
        String deviceCode,
        String devEui,
        String deviceType
) {
}
