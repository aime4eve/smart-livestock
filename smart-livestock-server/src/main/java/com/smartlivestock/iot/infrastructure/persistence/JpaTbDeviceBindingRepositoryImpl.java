package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.TbDeviceBinding;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.TbDeviceBindingJpaEntity;
import com.smartlivestock.iot.infrastructure.persistence.mapper.TbDeviceBindingMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaTbDeviceBindingRepositoryImpl implements TbDeviceBindingRepository {

    private final SpringDataTbDeviceBindingRepository springDataRepo;

    @Override
    public TbDeviceBinding save(TbDeviceBinding binding) {
        TbDeviceBindingJpaEntity saved = springDataRepo.save(TbDeviceBindingMapper.toJpaEntity(binding));
        return TbDeviceBindingMapper.toDomain(saved);
    }

    @Override
    public Optional<TbDeviceBinding> findById(Long id) {
        return springDataRepo.findById(id).map(TbDeviceBindingMapper::toDomain);
    }

    @Override
    public List<TbDeviceBinding> findByStatus(TbDeviceBinding.Status status) {
        return springDataRepo.findByBindingStatus(status.name()).stream()
                .map(TbDeviceBindingMapper::toDomain)
                .toList();
    }

    @Override
    public Optional<TbDeviceBinding> findByDeviceIdAndProvider(Long deviceId, String provider) {
        return springDataRepo.findByDeviceIdAndProvider(deviceId, provider)
                .map(TbDeviceBindingMapper::toDomain);
    }

    @Override
    public boolean existsByDeviceIdAndProvider(Long deviceId, String provider) {
        return springDataRepo.existsByDeviceIdAndProvider(deviceId, provider);
    }
}
