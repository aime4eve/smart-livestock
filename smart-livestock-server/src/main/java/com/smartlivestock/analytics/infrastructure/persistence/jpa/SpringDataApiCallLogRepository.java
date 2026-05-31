package com.smartlivestock.analytics.infrastructure.persistence.jpa;

import com.smartlivestock.analytics.infrastructure.persistence.entity.ApiCallLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.Instant;
import java.util.List;

public interface SpringDataApiCallLogRepository extends JpaRepository<ApiCallLogJpaEntity, Long> {
    List<ApiCallLogJpaEntity> findByTenantIdAndRequestedAtBetween(Long tenantId, Instant from, Instant to);
    List<ApiCallLogJpaEntity> findByApiKeyIdAndRequestedAtBetween(Long apiKeyId, Instant from, Instant to);
    long countByTenantIdAndRequestedAtAfter(Long tenantId, Instant since);
    long deleteByRequestedAtBefore(Instant cutoff);
    List<ApiCallLogJpaEntity> findAllByRequestedAtBetween(Instant from, Instant to);
}
