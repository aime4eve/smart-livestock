package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.FenceZone;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.FenceZoneMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaFenceZoneRepositoryImpl implements FenceZoneRepository {

    private final SpringDataFenceZoneRepository springDataRepo;

    @Override
    public FenceZone save(FenceZone zone) {
        return FenceZoneMapper.toDomain(
                springDataRepo.save(FenceZoneMapper.toJpaEntity(zone)));
    }

    @Override
    public Optional<FenceZone> findById(Long id) {
        return springDataRepo.findById(id).map(FenceZoneMapper::toDomain);
    }

    @Override
    public List<FenceZone> findByFarmId(Long farmId) {
        return springDataRepo.findByFarmId(farmId).stream()
                .map(FenceZoneMapper::toDomain)
                .toList();
    }
}
