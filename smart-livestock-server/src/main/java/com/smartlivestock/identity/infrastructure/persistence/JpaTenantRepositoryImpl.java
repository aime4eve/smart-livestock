package com.smartlivestock.identity.infrastructure.persistence;

import com.smartlivestock.identity.domain.model.Tenant;
import com.smartlivestock.identity.domain.repository.TenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.entity.TenantJpaEntity;
import com.smartlivestock.identity.infrastructure.persistence.mapper.TenantMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaTenantRepositoryImpl implements TenantRepository {

    private final SpringDataTenantRepository springDataRepo;

    @Override
    public Tenant save(Tenant tenant) {
        if (tenant.getId() != null) {
            var existing = springDataRepo.findById(tenant.getId()).orElse(null);
            TenantJpaEntity jpa = existing != null ? existing : TenantMapper.toJpaEntity(tenant);
            TenantMapper.applyTo(jpa, tenant);
            return TenantMapper.toDomain(springDataRepo.save(jpa));
        }
        return TenantMapper.toDomain(springDataRepo.save(TenantMapper.toJpaEntity(tenant)));
    }

    @Override
    public Optional<Tenant> findById(Long id) {
        return springDataRepo.findById(id).map(TenantMapper::toDomain);
    }

    @Override
    public boolean existsById(Long id) {
        return springDataRepo.existsById(id);
    }
}
