package com.smartlivestock.iot.application.dto;

/**
 * Platform-admin device handover lookup (ruling 2026-10-19): where does an
 * EUI live today, and can it be handed over. {@code found=false} for an
 * unknown EUI; {@code activeInstallation=true} blocks the transfer until the
 * device is unbound.
 */
public record DeviceTransferLookupDto(
        boolean found,
        Long deviceId,
        String deviceCode,
        String deviceType,
        String status,
        Long tenantId,
        String tenantName,
        boolean activeInstallation
) {
    public static DeviceTransferLookupDto notFound() {
        return new DeviceTransferLookupDto(false, null, null, null, null, null, null, false);
    }
}
