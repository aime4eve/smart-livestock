package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.ActivateLicenseCommand;
import com.smartlivestock.iot.application.dto.DeviceLicenseDto;
import com.smartlivestock.iot.domain.model.DeviceLicense;
import com.smartlivestock.iot.domain.model.LicenseStatus;
import com.smartlivestock.iot.domain.repository.DeviceLicenseRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DeviceLicenseApplicationService {

    private final DeviceLicenseRepository deviceLicenseRepository;

    private static final long DEFAULT_LICENSE_DURATION_DAYS = 365;

    @Transactional
    public DeviceLicenseDto activateLicense(ActivateLicenseCommand command) {
        String licenseKey = UUID.randomUUID().toString();
        Instant expiresAt = Instant.now().plusSeconds(DEFAULT_LICENSE_DURATION_DAYS * 86400L);
        DeviceLicense license = new DeviceLicense(command.deviceId(), command.tenantId(), licenseKey, expiresAt);
        DeviceLicense saved = deviceLicenseRepository.save(license);
        return DeviceLicenseDto.from(saved);
    }

    @Transactional(readOnly = true)
    public DeviceLicenseDto getByDeviceId(Long deviceId) {
        List<DeviceLicense> licenses = deviceLicenseRepository.findByDeviceId(deviceId);
        if (licenses.isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "设备无License: " + deviceId);
        }
        // Return the most recently created license
        return DeviceLicenseDto.from(licenses.get(licenses.size() - 1));
    }

    @Transactional
    public void checkExpired() {
        // License expiry is checked on-demand via DeviceLicense.isExpired().
        // This method can be used by a scheduled job to bulk-update EXPIRED status.
        // For now, the domain model handles validity checks directly.
    }

    @Transactional(readOnly = true)
    public DeviceLicenseDto findById(Long id) {
        DeviceLicense license = deviceLicenseRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "许可证不存在: " + id));
        return DeviceLicenseDto.from(license);
    }

    @Transactional(readOnly = true)
    public List<DeviceLicenseDto> listByTenant(Long tenantId) {
        return deviceLicenseRepository.findByTenantId(tenantId).stream()
                .map(DeviceLicenseDto::from)
                .toList();
    }

    @Transactional
    public DeviceLicenseDto revoke(Long id) {
        DeviceLicense license = deviceLicenseRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "许可证不存在: " + id));
        license.revoke();
        DeviceLicense saved = deviceLicenseRepository.save(license);
        return DeviceLicenseDto.from(saved);
    }
}
