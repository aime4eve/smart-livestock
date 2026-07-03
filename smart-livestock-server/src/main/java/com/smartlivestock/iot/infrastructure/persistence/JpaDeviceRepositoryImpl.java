package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceJpaEntity;
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
        DeviceJpaEntity jpaEntity = DeviceMapper.toJpaEntity(device);
        if (device.getId() != null) {
            springDataRepo.findById(device.getId())
                    .ifPresent(existing -> jpaEntity.setCreatedAt(existing.getCreatedAt()));
        }
        return DeviceMapper.toDomain(springDataRepo.save(jpaEntity));
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

    @Override
    public long countByTenantIdAndStatus(Long tenantId, String status) {
        return springDataRepo.countByTenantIdAndStatus(tenantId, status);
    }

    @Override
    public List<Device> findByTenantIdPaged(Long tenantId, int offset, int limit) {
        org.springframework.data.domain.Pageable pageable =
                org.springframework.data.domain.PageRequest.of(offset / limit, limit);
        return springDataRepo.findByTenantIdPaged(tenantId, pageable)
                .stream().map(DeviceMapper::toDomain).toList();
    }

    @Override
    public List<Device> findByTenantIdAndKeyword(Long tenantId, String keyword, int offset, int limit) {
        org.springframework.data.domain.Pageable pageable =
                org.springframework.data.domain.PageRequest.of(offset / limit, limit);
        return springDataRepo.findByTenantIdAndKeyword(tenantId, keyword, pageable)
                .stream().map(DeviceMapper::toDomain).toList();
    }

    @Override
    public long countByTenantIdPaged(Long tenantId) {
        return springDataRepo.countByTenantIdActive(tenantId);
    }

    @Override
    public long countByTenantIdAndKeyword(Long tenantId, String keyword) {
        return springDataRepo.countByTenantIdAndKeyword(tenantId, keyword);
    }
}
