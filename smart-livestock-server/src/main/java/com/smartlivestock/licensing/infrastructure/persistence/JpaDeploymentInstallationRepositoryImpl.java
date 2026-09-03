package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.domain.DeploymentInstallation;
import com.smartlivestock.licensing.domain.repository.DeploymentInstallationRepository;
import com.smartlivestock.licensing.infrastructure.persistence.mapper.DeploymentInstallationMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeploymentInstallationRepositoryImpl implements DeploymentInstallationRepository {

    private final SpringDataDeploymentInstallationRepository springDataRepo;

    @Override
    public Optional<DeploymentInstallation> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId)
                .map(DeploymentInstallationMapper::toDomain);
    }

    @Override
    public DeploymentInstallation save(DeploymentInstallation installation) {
        return DeploymentInstallationMapper.toDomain(
                springDataRepo.save(DeploymentInstallationMapper.toEntity(installation)));
    }

    @Override
    public List<Long> findAllTenantIds() {
        return springDataRepo.findAllTenantIds();
    }
}
