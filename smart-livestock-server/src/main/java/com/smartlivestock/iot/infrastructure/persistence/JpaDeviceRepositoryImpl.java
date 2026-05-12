package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.persistence.mapper.DeviceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeviceRepositoryImpl implements DeviceRepository {

    private final SpringDataDeviceRepository springDataRepo;

    @Override
    public Device save(Device device) {
        return DeviceMapper.toDomain(springDataRepo.save(DeviceMapper.toJpaEntity(device)));
    }

    @Override
    public Optional<Device> findById(Long id) {
        return springDataRepo.findById(id).map(DeviceMapper::toDomain);
    }

    @Override
    public Optional<Device> findByDeviceCode(String deviceCode) {
        return springDataRepo.findByDeviceCode(deviceCode).map(DeviceMapper::toDomain);
    }

    @Override
    public List<Device> findByTenantId(Long tenantId) {
        return springDataRepo.findByTenantId(tenantId).stream()
                .map(DeviceMapper::toDomain)
                .toList();
    }
}
