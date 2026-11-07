package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.PlatformDisplaySettingsJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataPlatformDisplaySettingsRepository
        extends JpaRepository<PlatformDisplaySettingsJpaEntity, Long> {

    /** Single-row table: the seed row is always the lowest id. */
    java.util.Optional<PlatformDisplaySettingsJpaEntity> findFirstByOrderByIdAsc();
}
