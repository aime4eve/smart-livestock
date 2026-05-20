package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.RevenuePeriodJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SpringDataRevenuePeriodRepository extends JpaRepository<RevenuePeriodJpaEntity, Long> {
    List<RevenuePeriodJpaEntity> findByContractId(Long contractId);
    List<RevenuePeriodJpaEntity> findByTenantId(Long tenantId);
}
