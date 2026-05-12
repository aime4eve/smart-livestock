package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.Farm;
import com.smartlivestock.identity.domain.repository.FarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.FarmJpaEntity;
import com.smartlivestock.identity.infrastructure.persistence.mapper.FarmMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaFarmRepositoryImpl implements FarmRepository {

    private final SpringDataFarmRepository springDataRepo;

    @Override
    public Farm save(Farm farm) {
        return FarmMapper.toDomain(springDataRepo.save(FarmMapper.toJpaEntity(farm)));
    }

    @Override
    public Optional<Farm> findById(Long id) {
        return springDataRepo.findById(id).map(FarmMapper::toDomain);
    }

    @Override
    public List<Farm> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId).stream()
                .map(FarmMapper::toDomain)
                .toList();
    }

    @Override
    public void deleteById(Long id) {
        // Soft delete: set deletedAt timestamp
        springDataRepo.findById(id).ifPresent(jpa -> {
            jpa.setDeletedAt(Instant.now());
            springDataRepo.save(jpa);
        });
    }
}
