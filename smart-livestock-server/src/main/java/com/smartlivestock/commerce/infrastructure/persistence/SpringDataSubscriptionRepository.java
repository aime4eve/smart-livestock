package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface SpringDataSubscriptionRepository extends JpaRepository<SubscriptionJpaEntity, Long> {
    Optional<SubscriptionJpaEntity> findByTenantId(Long tenantId);

    @Query("SELECT s.status FROM SubscriptionJpaEntity s WHERE s.tenantId = :tenantId")
    Optional<String> findStatusByTenantId(Long tenantId);
}
