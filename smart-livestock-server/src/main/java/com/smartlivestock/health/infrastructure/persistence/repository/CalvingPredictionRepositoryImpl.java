package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.CalvingPrediction;
import com.smartlivestock.health.domain.repository.CalvingPredictionRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.CalvingPredictionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class CalvingPredictionRepositoryImpl implements CalvingPredictionRepository {

    private final CalvingPredictionJpaRepository jpaRepo;

    @Override
    public CalvingPrediction save(CalvingPrediction prediction) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(prediction)));
    }

    @Override
    public Optional<CalvingPrediction> findLatestByLivestockId(Long livestockId) {
        return jpaRepo.findTopByLivestockIdOrderByPredictedAtDesc(livestockId)
                .map(HealthMapper::toDomain);
    }

    @Override
    public List<CalvingPrediction> findByLivestockIdOrderByPredictedAtDesc(Long livestockId, int limit) {
        return jpaRepo.findByLivestockIdOrderByPredictedAtDesc(livestockId).stream()
                .limit(limit).map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<CalvingPrediction> findLatestPerLivestockByFarm(Long farmId, int limit) {
        return jpaRepo.findLatestPerLivestockByFarm(farmId, limit).stream()
                .map(HealthMapper::toDomain).toList();
    }
}
