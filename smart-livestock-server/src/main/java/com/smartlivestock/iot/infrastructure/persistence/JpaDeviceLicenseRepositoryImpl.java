package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.DeviceLicense;
import com.smartlivestock.iot.domain.repository.DeviceLicenseRepository;
import com.smartlivestock.iot.infrastructure.persistence.mapper.DeviceLicenseMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeviceLicenseRepositoryImpl implements DeviceLicenseRepository {

    private final SpringDataDeviceLicenseRepository springDataRepo;

    @Override
    public DeviceLicense save(DeviceLicense license) {
        return DeviceLicenseMapper.toDomain(springDataRepo.save(DeviceLicenseMapper.toJpaEntity(license)));
    }

    @Override
    public List<DeviceLicense> findByDeviceId(Long deviceId) {
        return springDataRepo.findByDeviceId(deviceId).stream()
                .map(DeviceLicenseMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<DeviceLicense> findByLicenseKey(String licenseKey) {
        return springDataRepo.findByLicenseKey(licenseKey).map(DeviceLicenseMapper::toDomain);
    }

    @Override
    public Optional<DeviceLicense> findById(Long id) {
        return springDataRepo.findById(id).map(DeviceLicenseMapper::toDomain);
    }

    @Override
    public List<DeviceLicense> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId).stream()
                .map(DeviceLicenseMapper::toDomain)
                .toList();
    }
}
