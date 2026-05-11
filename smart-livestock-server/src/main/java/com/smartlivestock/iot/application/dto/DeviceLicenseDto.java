package com.smartlivestock.iot.application.dto;

import com.smartlivestock.iot.domain.model.DeviceLicense;

import java.time.Instant;

public record DeviceLicenseDto(
        Long id,
        Long deviceId,
        Long tenantId,
        String licenseKey,
        String status,
        Instant activatedAt,
        Instant expiresAt
) {
    public static DeviceLicenseDto from(DeviceLicense license) {
        return new DeviceLicenseDto(
                license.getId(),
                license.getDeviceId(),
                license.getTenantId(),
                license.getLicenseKey(),
                license.getStatus().name(),
                license.getActivatedAt(),
                license.getExpiresAt()
        );
    }
}
