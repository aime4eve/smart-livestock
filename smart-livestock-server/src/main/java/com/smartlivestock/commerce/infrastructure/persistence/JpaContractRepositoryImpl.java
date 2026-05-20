package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.model.Contract;
import com.smartlivestock.commerce.domain.model.ContractStatus;
import com.smartlivestock.commerce.domain.repository.ContractRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.ContractMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaContractRepositoryImpl implements ContractRepository {

    private final SpringDataContractRepository springDataRepo;

    @Override
    public Optional<Contract> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId)
                .map(ContractMapper::toDomain);
    }

    @Override
    public Optional<Contract> findById(Long id) {
        return springDataRepo.findById(id)
                .map(ContractMapper::toDomain);
    }

    @Override
    public List<Contract> findByStatus(ContractStatus status) {
        return springDataRepo.findByStatus(status.name().toLowerCase()).stream()
                .map(ContractMapper::toDomain)
                .toList();
    }

    @Override
    public Contract save(Contract contract) {
        if (contract.getId() != null) {
            return springDataRepo.findById(contract.getId())
                    .map(existing -> {
                        ContractMapper.updateEntity(existing, contract);
                        return ContractMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> ContractMapper.toDomain(springDataRepo.save(
                            ContractMapper.toJpaEntity(contract))));
        }
        return ContractMapper.toDomain(springDataRepo.save(
                ContractMapper.toJpaEntity(contract)));
    }
}
