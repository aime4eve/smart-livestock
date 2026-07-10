package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class TemperatureLogRepositoryImpl implements TemperatureLogRepository {

    private final TemperatureLogJpaRepository jpaRepo;

    @Override
    public List<TemperatureLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to) {
        return jpaRepo.findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(livestockId, from, to)
                .stream().map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<TemperatureLog> findLatestByLivestockIds(List<Long> livestockIds, int limitPerLivestock) {
        return livestockIds.stream()
                .flatMap(id -> jpaRepo.findByLivestockIdOrderByRecordedAtDesc(id).stream().limit(limitPerLivestock))
                .map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<TemperatureLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit) {
        return jpaRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId).stream()
                .limit(limit).map(HealthMapper::toDomain).toList();
    }

    @Override
    public TemperatureLog save(TemperatureLog log) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(log)));
    }
}
