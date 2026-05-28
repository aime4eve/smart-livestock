package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.FarmTileTask;
import com.smartlivestock.ranch.domain.repository.FarmTileTaskRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.FarmTileTaskMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class FarmTileTaskRepositoryImpl implements FarmTileTaskRepository {
    private final SpringDataFarmTileTaskRepository springDataRepo;

    @Override
    public FarmTileTask save(FarmTileTask task) {
        return FarmTileTaskMapper.toDomain(springDataRepo.save(FarmTileTaskMapper.toJpaEntity(task)));
    }
    @Override
    public Optional<FarmTileTask> findById(Long id) {
        return springDataRepo.findById(id).map(FarmTileTaskMapper::toDomain);
    }
    @Override
    public List<FarmTileTask> findByFarmId(Long farmId) {
        return springDataRepo.findByFarmId(farmId).stream().map(FarmTileTaskMapper::toDomain).toList();
    }
    @Override
    public Optional<FarmTileTask> findByFarmIdAndRegionId(Long farmId, Long regionId) {
        return springDataRepo.findByFarmIdAndRegionId(farmId, regionId).map(FarmTileTaskMapper::toDomain);
    }
    @Override
    public List<FarmTileTask> findAll() {
        return springDataRepo.findAll().stream().map(FarmTileTaskMapper::toDomain).toList();
    }
}
