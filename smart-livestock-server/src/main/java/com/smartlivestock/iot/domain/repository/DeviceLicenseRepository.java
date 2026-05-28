package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceLicense;

import java.util.List;
import java.util.Optional;

public interface DeviceLicenseRepository {
    DeviceLicense save(DeviceLicense license);
    List<DeviceLicense> findByDeviceId(Long deviceId);
    Optional<DeviceLicense> findByLicenseKey(String licenseKey);
}
