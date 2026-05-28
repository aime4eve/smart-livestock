package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.model.RevenuePeriod;
import com.smartlivestock.commerce.domain.repository.RevenuePeriodRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.RevenuePeriodMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaRevenuePeriodRepositoryImpl implements RevenuePeriodRepository {

    private final SpringDataRevenuePeriodRepository springDataRepo;

    @Override
    public List<RevenuePeriod> findByContractId(Long contractId) {
        return springDataRepo.findByContractId(contractId).stream()
                .map(RevenuePeriodMapper::toDomain)
                .toList();
    }

    @Override
    public List<RevenuePeriod> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId).stream()
                .map(RevenuePeriodMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<RevenuePeriod> findById(Long id) {
        return springDataRepo.findById(id)
                .map(RevenuePeriodMapper::toDomain);
    }

    @Override
    public RevenuePeriod save(RevenuePeriod revenuePeriod) {
        if (revenuePeriod.getId() != null) {
            return springDataRepo.findById(revenuePeriod.getId())
                    .map(existing -> {
                        RevenuePeriodMapper.updateEntity(existing, revenuePeriod);
                        return RevenuePeriodMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> RevenuePeriodMapper.toDomain(springDataRepo.save(
                            RevenuePeriodMapper.toJpaEntity(revenuePeriod))));
        }
        return RevenuePeriodMapper.toDomain(springDataRepo.save(
                RevenuePeriodMapper.toJpaEntity(revenuePeriod)));
    }
}
