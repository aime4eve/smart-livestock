package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionHealthSettingsJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SpringDataSubscriptionHealthSettingsRepository
        extends JpaRepository<SubscriptionHealthSettingsJpaEntity, Long> {

    /** Single-row table: the seed row is always the lowest id. */
    java.util.Optional<SubscriptionHealthSettingsJpaEntity> findFirstByOrderByIdAsc();
}
