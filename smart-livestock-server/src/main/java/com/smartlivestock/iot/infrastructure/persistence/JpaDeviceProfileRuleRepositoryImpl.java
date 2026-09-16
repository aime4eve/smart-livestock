package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.DeviceProfileRule;
import com.smartlivestock.iot.domain.repository.DeviceProfileRuleRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceProfileRuleJpaEntity;
import com.smartlivestock.iot.infrastructure.persistence.mapper.DeviceProfileRuleMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeviceProfileRuleRepositoryImpl implements DeviceProfileRuleRepository {

    private final SpringDataDeviceProfileRuleRepository springDataRepo;

    @Override
    public DeviceProfileRule save(DeviceProfileRule rule) {
        DeviceProfileRuleJpaEntity saved = springDataRepo.save(DeviceProfileRuleMapper.toJpaEntity(rule));
        return DeviceProfileRuleMapper.toDomain(saved);
    }

    @Override
    public Optional<DeviceProfileRule> findById(Long id) {
        return springDataRepo.findById(id).map(DeviceProfileRuleMapper::toDomain);
    }

    @Override
    public List<DeviceProfileRule> findAllOrderedByName() {
        return springDataRepo.findAllByOrderByProfileNameAsc().stream()
                .map(DeviceProfileRuleMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<DeviceProfileRule> findByProfileName(String profileName) {
        return springDataRepo.findByProfileName(profileName).map(DeviceProfileRuleMapper::toDomain);
    }

    @Override
    public boolean existsByProfileName(String profileName) {
        return springDataRepo.existsByProfileName(profileName);
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }
}
