package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.HealthSnapshotJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class HealthSnapshotRepositoryImpl implements HealthSnapshotRepository {

    private final HealthSnapshotJpaRepository jpaRepo;

    @Override
    public List<HealthSnapshot> findByFarmId(Long farmId) {
        return jpaRepo.findByFarmId(farmId).stream().map(HealthMapper::toDomain).toList();
    }

    @Override
    public Optional<HealthSnapshot> findByLivestockId(Long livestockId) {
        return jpaRepo.findByLivestockId(livestockId).map(HealthMapper::toDomain);
    }

    @Override
    public HealthSnapshot save(HealthSnapshot snapshot) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(snapshot)));
    }
}
