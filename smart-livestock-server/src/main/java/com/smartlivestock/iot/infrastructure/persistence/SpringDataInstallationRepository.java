package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.InstallationJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataInstallationRepository extends JpaRepository<InstallationJpaEntity, Long> {
    Optional<InstallationJpaEntity> findByDeviceIdAndRemovedAtIsNull(Long deviceId);
    List<InstallationJpaEntity> findByLivestockId(Long livestockId);
    Optional<InstallationJpaEntity> findByLivestockIdAndRemovedAtIsNull(Long livestockId);
    List<InstallationJpaEntity> findByRemovedAtIsNull();
}
