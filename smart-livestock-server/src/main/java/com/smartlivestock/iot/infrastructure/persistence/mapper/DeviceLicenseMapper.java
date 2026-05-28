package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.DeviceLicense;
import com.smartlivestock.iot.domain.model.LicenseStatus;
import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceLicenseJpaEntity;

public final class DeviceLicenseMapper {

    private DeviceLicenseMapper() {}

    public static DeviceLicenseJpaEntity toJpaEntity(DeviceLicense license) {
        DeviceLicenseJpaEntity jpa = new DeviceLicenseJpaEntity();
        jpa.setId(license.getId());
        jpa.setDeviceId(license.getDeviceId());
        jpa.setTenantId(license.getTenantId());
        jpa.setLicenseKey(license.getLicenseKey());
        jpa.setStatus(license.getStatus().name());
        jpa.setActivatedAt(license.getActivatedAt());
        jpa.setExpiresAt(license.getExpiresAt());
        return jpa;
    }

    public static DeviceLicense toDomain(DeviceLicenseJpaEntity jpa) {
        DeviceLicense license = new DeviceLicense();
        license.setId(jpa.getId());
        license.setDeviceId(jpa.getDeviceId());
        license.setTenantId(jpa.getTenantId());
        license.setLicenseKey(jpa.getLicenseKey());
        license.setStatus(LicenseStatus.valueOf(jpa.getStatus()));
        license.reconstituteActivatedAt(jpa.getActivatedAt());
        license.setExpiresAt(jpa.getExpiresAt());
        return license;
    }
}
