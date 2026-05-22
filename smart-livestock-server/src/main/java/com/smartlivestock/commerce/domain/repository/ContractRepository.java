package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.ContractStatus;

import java.util.List;
import java.util.Optional;

public interface ContractRepository {
    Optional<Contract> findByTenantId(Long tenantId);
    Optional<Contract> findById(Long id);
    List<Contract> findByStatus(ContractStatus status);
    Contract save(Contract contract);
}
