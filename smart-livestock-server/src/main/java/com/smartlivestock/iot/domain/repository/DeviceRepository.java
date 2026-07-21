package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.Device;

import java.util.Collection;
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

    /** Find IDs of ACTIVE devices with platform_device_id set, paginated by offset/limit. */
    List<Long> findActivePlatformDeviceIds(int offset, int limit);

    /** All TRACKER devices across tenants (for GPS quality admin). */
    List<Device> findAllTrackers();

    /** Devices matching the given ids (cross-tenant lookup for device codes). */
    List<Device> findAllByIdIn(Collection<Long> ids);

    /** Lookup by devEui including soft-deleted rows (revive detection on re-add paths). */
    List<Device> findAllByDevEuiAndTenantIdIncludeDeleted(String devEui, Long tenantId);

    /**
     * Revive persistence: native UPDATE clearing deleted_at, resetting status to INVENTORY
     * and writing the final deviceCode (must already be checked against the active set).
     * Must run before save() on a soft-deleted row (see Device.restore()).
     */
    void restoreById(Long id, String deviceCode);
}
