package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataDeviceRepository extends JpaRepository<DeviceJpaEntity, Long> {
   Optional<DeviceJpaEntity> findByDeviceCode(String deviceCode);
    List<DeviceJpaEntity> findAllByDevEuiAndTenantId(String devEui, Long tenantId);
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

}
