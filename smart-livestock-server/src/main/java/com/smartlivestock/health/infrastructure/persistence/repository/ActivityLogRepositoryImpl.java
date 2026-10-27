package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.shared.domain.TelemetryPage;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.ActivityLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
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
    public TelemetryPage<ActivityLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize) {
        return toPage(jpaRepo.findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(
                        livestockId, from, to, PageRequest.of(Math.max(0, page - 1), pageSize))
                .map(HealthMapper::toDomain), page, pageSize);
    }


    @Override
    public com.smartlivestock.shared.domain.TelemetryPage<ActivityLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable) {
        if (livestockIds == null || livestockIds.isEmpty()) {
            return com.smartlivestock.shared.domain.TelemetryPage.empty(pageable.getPageNumber() + 1, pageable.getPageSize());
        }
        return toPage(jpaRepo.findPageByLivestockIdIn(livestockIds, pageable).map(HealthMapper::toDomain),
                pageable.getPageNumber() + 1, pageable.getPageSize());
    }

    private static <T> TelemetryPage<T> toPage(Page<T> result, int page, int pageSize) {
        return new TelemetryPage<>(result.getContent(), page, pageSize, result.getTotalElements());
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
