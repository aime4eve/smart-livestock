package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.RevenuePeriod;

import java.util.List;
import java.util.Optional;

public interface RevenuePeriodRepository {
    List<RevenuePeriod> findByContractId(Long contractId);
    List<RevenuePeriod> findByTenantId(Long tenantId);
    Optional<RevenuePeriod> findById(Long id);
    RevenuePeriod save(RevenuePeriod revenuePeriod);
}
