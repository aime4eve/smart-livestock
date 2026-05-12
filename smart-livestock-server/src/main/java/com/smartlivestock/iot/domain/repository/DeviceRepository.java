package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.Device;

import java.util.List;
import java.util.Optional;

public interface DeviceRepository {
    Device save(Device device);
    Optional<Device> findById(Long id);
    Optional<Device> findByDeviceCode(String deviceCode);
    List<Device> findByTenantId(Long tenantId);
}
