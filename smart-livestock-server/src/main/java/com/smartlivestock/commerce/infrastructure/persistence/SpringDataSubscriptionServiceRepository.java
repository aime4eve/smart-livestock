package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionServiceJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataSubscriptionServiceRepository extends JpaRepository<SubscriptionServiceJpaEntity, Long> {
    Optional<SubscriptionServiceJpaEntity> findByTenantId(Long tenantId);

    List<SubscriptionServiceJpaEntity> findByStatus(String status);
}
