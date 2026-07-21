package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataDeviceRepository extends JpaRepository<DeviceJpaEntity, Long> {
   Optional<DeviceJpaEntity> findByDeviceCode(String deviceCode);
   List<DeviceJpaEntity> findByTenantId(Long tenantId);
    long countByTenantIdAndStatus(Long tenantId, String status);

    @Query("SELECT d FROM DeviceJpaEntity d WHERE d.tenantId = :tenantId ORDER BY d.id")
    Page<DeviceJpaEntity> findByTenantIdPaged(@Param("tenantId") Long tenantId, Pageable pageable);

    @Query("SELECT d FROM DeviceJpaEntity d WHERE d.tenantId = :tenantId " +
           "AND (LOWER(d.deviceCode) LIKE LOWER(CONCAT('%', :keyword, '%'))) ORDER BY d.id")
    Page<DeviceJpaEntity> findByTenantIdAndKeyword(@Param("tenantId") Long tenantId,
                                                   @Param("keyword") String keyword,
                                                   Pageable pageable);

    @Query("SELECT COUNT(d) FROM DeviceJpaEntity d WHERE d.tenantId = :tenantId")
    long countByTenantIdActive(@Param("tenantId") Long tenantId);

    @Query("SELECT COUNT(d) FROM DeviceJpaEntity d WHERE d.tenantId = :tenantId " +
           "AND (LOWER(d.deviceCode) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    long countByTenantIdAndKeyword(@Param("tenantId") Long tenantId, @Param("keyword") String keyword);

    @Query("SELECT d.id FROM DeviceJpaEntity d WHERE d.status = 'ACTIVE' AND d.platformDeviceId IS NOT NULL ORDER BY d.id")
    List<Long> findActivePlatformDeviceIds(Pageable pageable);

    List<DeviceJpaEntity> findByDeviceTypeOrderById(@Param("deviceType") String deviceType);

    /**
     * Lookup by devEui including soft-deleted rows (native query bypasses @SQLRestriction).
     * Used for revive detection on the re-add paths.
     */
    @Query(value = "SELECT * FROM devices WHERE dev_eui = :devEui AND tenant_id = :tenantId",
           nativeQuery = true)
    List<DeviceJpaEntity> findAllByDevEuiAndTenantIdIncludeDeleted(@Param("devEui") String devEui,
                                                                   @Param("tenantId") Long tenantId);

    /**
     * Revive persistence: native UPDATE to clear deleted_at and reset status to INVENTORY.
     * Semantics must stay consistent with {@code Device.restore()} (both reset to INVENTORY).
     * Must run before save() so the merge-internal SELECT can load the row again.
     * device_code is written in the same statement with the FINAL code (already checked
     * against the active set by the caller): the soft-deleted row's own old code may
     * collide with another active row, and clearing deleted_at alone would violate
     * uq_devices_code_active before save() could update the code.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = "UPDATE devices SET deleted_at = NULL, status = 'INVENTORY', device_code = :deviceCode WHERE id = :id",
           nativeQuery = true)
    int restoreById(@Param("id") Long id, @Param("deviceCode") String deviceCode);
}
