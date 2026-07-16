package com.smartlivestock.analytics.infrastructure.persistence.jpa;

import com.smartlivestock.analytics.infrastructure.persistence.entity.ApiUsageDailyJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;

public interface SpringDataApiUsageDailyRepository extends JpaRepository<ApiUsageDailyJpaEntity, Long> {
    List<ApiUsageDailyJpaEntity> findByTenantIdAndUsageDateBetween(Long tenantId, LocalDate from, LocalDate to);
    List<ApiUsageDailyJpaEntity> findByApiKeyIdAndUsageDateBetween(Long apiKeyId, LocalDate from, LocalDate to);
    List<ApiUsageDailyJpaEntity> findAllByUsageDateBetween(LocalDate from, LocalDate to);
}
