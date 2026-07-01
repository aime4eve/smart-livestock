package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.InstallationJpaEntity;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataInstallationRepository extends JpaRepository<InstallationJpaEntity, Long> {
    Optional<InstallationJpaEntity> findByDeviceIdAndRemovedAtIsNull(Long deviceId);
    List<InstallationJpaEntity> findByLivestockId(Long livestockId);
    Optional<InstallationJpaEntity> findByLivestockIdAndRemovedAtIsNull(Long livestockId);
    List<InstallationJpaEntity> findByRemovedAtIsNull();
    List<InstallationJpaEntity> findByLivestockIdIn(List<Long> livestockIds);

    @Query("SELECT i FROM InstallationJpaEntity i JOIN DeviceJpaEntity d ON i.deviceId = d.id " +
           "WHERE i.livestockId = :livestockId AND i.removedAt IS NULL AND d.deviceType = :deviceType")
    Optional<InstallationJpaEntity> findActiveByLivestockIdAndDeviceType(
            @Param("livestockId") Long livestockId, @Param("deviceType") String deviceType);
}
