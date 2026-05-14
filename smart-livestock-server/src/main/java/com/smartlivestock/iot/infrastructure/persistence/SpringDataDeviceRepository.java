package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataDeviceRepository extends JpaRepository<DeviceJpaEntity, Long> {
    Optional<DeviceJpaEntity> findByDeviceCode(String deviceCode);
    List<DeviceJpaEntity> findByTenantId(Long tenantId);
    long countByTenantIdAndStatus(Long tenantId, String status);
}
