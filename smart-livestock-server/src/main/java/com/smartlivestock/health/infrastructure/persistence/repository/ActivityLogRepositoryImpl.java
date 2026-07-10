package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.ActivityLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class ActivityLogRepositoryImpl implements ActivityLogRepository {

    private final ActivityLogJpaRepository jpaRepo;

    @Override
    public List<ActivityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to) {
        return jpaRepo.findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(livestockId, from, to)
                .stream().map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<ActivityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit) {
        return jpaRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId).stream()
                .limit(limit).map(HealthMapper::toDomain).toList();
    }

    @Override
    public ActivityLog save(ActivityLog log) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(log)));
    }
}
