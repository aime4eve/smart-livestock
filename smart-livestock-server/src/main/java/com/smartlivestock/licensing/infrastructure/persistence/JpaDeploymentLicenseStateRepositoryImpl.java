package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.licensing.infrastructure.persistence.mapper.DeploymentLicenseStateMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeploymentLicenseStateRepositoryImpl implements DeploymentLicenseStateRepository {

    private final SpringDataDeploymentLicenseStateRepository springDataRepo;

    @Override
    public Optional<DeploymentLicenseState> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId)
                .map(DeploymentLicenseStateMapper::toDomain);
    }

    @Override
    public DeploymentLicenseState save(DeploymentLicenseState state) {
        return DeploymentLicenseStateMapper.toDomain(
                springDataRepo.save(DeploymentLicenseStateMapper.toEntity(state)));
    }
}
