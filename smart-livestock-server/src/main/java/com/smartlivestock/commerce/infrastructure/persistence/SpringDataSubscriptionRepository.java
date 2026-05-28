package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface SpringDataSubscriptionRepository extends JpaRepository<SubscriptionJpaEntity, Long> {
    Optional<SubscriptionJpaEntity> findByTenantId(Long tenantId);

    @Query("SELECT s.status FROM SubscriptionJpaEntity s WHERE s.tenantId = :tenantId")
    Optional<String> findStatusByTenantId(Long tenantId);

    List<SubscriptionJpaEntity> findByStatus(String status);

    @Query("SELECT s FROM SubscriptionJpaEntity s WHERE s.status = :status AND s.updatedAt < :cutoff")
    List<SubscriptionJpaEntity> findByStatusAndUpdatedAtBefore(String status, Instant cutoff);
}
