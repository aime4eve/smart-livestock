package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.Device;

import java.util.List;
import java.util.Optional;

public interface DeviceRepository {
    Device save(Device device);
    Optional<Device> findById(Long id);
    Optional<Device> findByDeviceCode(String deviceCode);
    List<Device> findByTenantId(Long tenantId);
    long countByTenantIdAndStatus(Long tenantId, String status);

    List<Device> findByTenantIdPaged(Long tenantId, int offset, int limit);
    List<Device> findByTenantIdAndKeyword(Long tenantId, String keyword, int offset, int limit);
    long countByTenantIdPaged(Long tenantId);
    long countByTenantIdAndKeyword(Long tenantId, String keyword);
}
