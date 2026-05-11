package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceLicenseJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataDeviceLicenseRepository extends JpaRepository<DeviceLicenseJpaEntity, Long> {
    List<DeviceLicenseJpaEntity> findByDeviceId(Long deviceId);
    Optional<DeviceLicenseJpaEntity> findByLicenseKey(String licenseKey);
}
