package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.infrastructure.persistence.mapper.InstallationMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaInstallationRepositoryImpl implements InstallationRepository {

    private final SpringDataInstallationRepository springDataRepo;

    @Override
    public Installation save(Installation installation) {
        return InstallationMapper.toDomain(springDataRepo.save(InstallationMapper.toJpaEntity(installation)));
    }

    @Override
    public Optional<Installation> findById(Long id) {
        return springDataRepo.findById(id).map(InstallationMapper::toDomain);
    }

    @Override
    public Optional<Installation> findActiveByDeviceId(Long deviceId) {
        return springDataRepo.findByDeviceIdAndRemovedAtIsNull(deviceId)
                .map(InstallationMapper::toDomain);
    }

    @Override
    public List<Installation> findByLivestockId(Long livestockId) {
        return springDataRepo.findByLivestockId(livestockId).stream()
                .map(InstallationMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<Installation> findActiveByLivestockId(Long livestockId) {
        return springDataRepo.findByLivestockIdAndRemovedAtIsNull(livestockId)
                .map(InstallationMapper::toDomain);
    }

    @Override
    public List<Installation> findAllActive() {
        return springDataRepo.findByRemovedAtIsNull().stream()
                .map(InstallationMapper::toDomain)
                .toList();
    }

    @Override
    public List<Installation> findByLivestockIdIn(List<Long> livestockIds) {
        return springDataRepo.findByLivestockIdIn(livestockIds).stream()
                .map(InstallationMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<Installation> findActiveByLivestockIdAndDeviceType(Long livestockId, DeviceType deviceType) {
        return springDataRepo.findActiveByLivestockIdAndDeviceType(livestockId, deviceType.name())
                .map(InstallationMapper::toDomain);
    }
}
