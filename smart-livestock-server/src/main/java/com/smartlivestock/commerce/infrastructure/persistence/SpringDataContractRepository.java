package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.ContractJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SpringDataContractRepository extends JpaRepository<ContractJpaEntity, Long> {
    Optional<ContractJpaEntity> findByTenantId(Long tenantId);
    List<ContractJpaEntity> findByStatus(String status);
}
