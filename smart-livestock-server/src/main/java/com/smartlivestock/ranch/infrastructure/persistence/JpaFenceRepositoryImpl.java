package com.smartlivestock.ranch.infrastructure.persistence;

import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.infrastructure.persistence.mapper.FenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaFenceRepositoryImpl implements FenceRepository {

    private final SpringDataFenceRepository springDataRepo;

    @Override
    public Fence save(Fence fence) {
        return FenceMapper.toDomain(springDataRepo.save(FenceMapper.toJpaEntity(fence)));
    }

    @Override
    public Optional<Fence> findById(Long id) {
        return springDataRepo.findById(id).map(FenceMapper::toDomain);
    }

    @Override
    public List<Fence> findByFarmId(Long farmId) {
        return springDataRepo.findByFarmId(farmId).stream()
                .map(FenceMapper::toDomain)
                .toList();
    }

    @Override
    public void deleteById(Long id) {
        springDataRepo.deleteById(id);
    }
}
