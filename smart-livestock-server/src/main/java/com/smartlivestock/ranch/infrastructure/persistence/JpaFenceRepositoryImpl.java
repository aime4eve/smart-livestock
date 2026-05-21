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
        if (fence.getId() != null) {
            return springDataRepo.findById(fence.getId())
                    .map(existing -> {
                        FenceMapper.updateEntity(existing, fence);
                        return FenceMapper.toDomain(springDataRepo.save(existing));
                    })
                    .orElseGet(() -> saveNew(fence));
        }
        return saveNew(fence);
    }

    private Fence saveNew(Fence fence) {
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

    @Override
    public long countByFarmId(Long farmId) {
        return springDataRepo.countByFarmId(farmId);
    }

    @Override
    public long countByFarmIdAndTenantId(Long farmId, Long tenantId) {
        return springDataRepo.countByFarmIdAndTenantId(farmId, tenantId);
    }
}
