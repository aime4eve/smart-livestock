package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.EstrusScore;
import com.smartlivestock.health.domain.repository.EstrusScoreRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.EstrusScoreJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class EstrusScoreRepositoryImpl implements EstrusScoreRepository {

    private final EstrusScoreJpaRepository jpaRepo;

    @Override
    public List<EstrusScore> findByFarmIdOrderByScoredAtDesc(Long farmId) {
        return jpaRepo.findByFarmIdOrderByScoredAtDesc(farmId).stream()
                .map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<EstrusScore> findByLivestockIdOrderByScoredAtDesc(Long livestockId, int limit) {
        return jpaRepo.findByLivestockIdOrderByScoredAtDesc(livestockId).stream()
                .limit(limit).map(HealthMapper::toDomain).toList();
    }

    @Override
    public Optional<EstrusScore> findLatestByLivestockId(Long livestockId) {
        return jpaRepo.findTopByLivestockIdOrderByScoredAtDesc(livestockId)
                .map(HealthMapper::toDomain);
    }

    @Override
    public EstrusScore save(EstrusScore score) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(score)));
    }
}
