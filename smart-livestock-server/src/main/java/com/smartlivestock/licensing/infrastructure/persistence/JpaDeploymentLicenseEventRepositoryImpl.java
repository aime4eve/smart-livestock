package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.domain.DeploymentLicenseEvent;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseEventRepository;
import com.smartlivestock.licensing.infrastructure.persistence.mapper.DeploymentLicenseEventMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

@Repository
@RequiredArgsConstructor
public class JpaDeploymentLicenseEventRepositoryImpl implements DeploymentLicenseEventRepository {

    private final SpringDataDeploymentLicenseEventRepository springDataRepo;

    @Override
    public DeploymentLicenseEvent save(DeploymentLicenseEvent event) {
        springDataRepo.save(DeploymentLicenseEventMapper.toEntity(event));
        return event;
    }
}
