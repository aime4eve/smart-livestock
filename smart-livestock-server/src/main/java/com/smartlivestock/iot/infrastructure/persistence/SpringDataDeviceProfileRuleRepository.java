package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceProfileRuleJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataDeviceProfileRuleRepository
        extends JpaRepository<DeviceProfileRuleJpaEntity, Long> {

    List<DeviceProfileRuleJpaEntity> findAllByOrderByProfileNameAsc();

    Optional<DeviceProfileRuleJpaEntity> findByProfileName(String profileName);

    boolean existsByProfileName(String profileName);
}
