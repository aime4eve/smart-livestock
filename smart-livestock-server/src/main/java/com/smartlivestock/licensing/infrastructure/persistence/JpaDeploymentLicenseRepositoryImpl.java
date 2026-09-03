package com.smartlivestock.licensing.infrastructure.persistence;

import com.smartlivestock.licensing.domain.DeploymentLicense;
import com.smartlivestock.licensing.domain.LicenseRecordStatus;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseRepository;
import com.smartlivestock.licensing.infrastructure.persistence.mapper.DeploymentLicenseMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaDeploymentLicenseRepositoryImpl implements DeploymentLicenseRepository {

    private final SpringDataDeploymentLicenseRepository springDataRepo;

    @Override
    public Optional<DeploymentLicense> findCurrentByTenantId(Long tenantId) {
        return springDataRepo
                .findFirstByTenantIdAndStatusOrderByAcceptedAtDesc(
                        tenantId, LicenseRecordStatus.CURRENT.name())
                .map(DeploymentLicenseMapper::toDomain);
    }

    @Override
    public Optional<DeploymentLicense> findByLicenseId(UUID licenseId) {
        return springDataRepo.findByLicenseId(licenseId)
                .map(DeploymentLicenseMapper::toDomain);
    }

    @Override
    public DeploymentLicense save(DeploymentLicense license) {
        return DeploymentLicenseMapper.toDomain(
                springDataRepo.save(DeploymentLicenseMapper.toEntity(license)));
    }
}
