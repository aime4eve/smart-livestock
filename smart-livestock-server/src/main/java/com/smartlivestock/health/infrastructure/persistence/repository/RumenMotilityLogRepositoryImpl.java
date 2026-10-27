package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.health.domain.model.RumenMotilityLog;
import com.smartlivestock.shared.domain.TelemetryPage;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.RumenMotilityLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class RumenMotilityLogRepositoryImpl implements RumenMotilityLogRepository {

    private final RumenMotilityLogJpaRepository jpaRepo;

    @Override
    public List<RumenMotilityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to) {
        return jpaRepo.findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(livestockId, from, to)
                .stream().map(HealthMapper::toDomain).toList();
    }

    @Override
    public TelemetryPage<RumenMotilityLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize) {
        return toPage(jpaRepo.findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(
                        livestockId, from, to, PageRequest.of(Math.max(0, page - 1), pageSize))
                .map(HealthMapper::toDomain), page, pageSize);
    }

    @Override
    public TelemetryPage<RumenMotilityLog> findPageByDevice(Long deviceId, Instant from, Instant to, int page, int pageSize) {
        return toPage(jpaRepo.findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
                        deviceId, from, to, PageRequest.of(Math.max(0, page - 1), pageSize))
                .map(HealthMapper::toDomain), page, pageSize);
    }


    @Override
    public com.smartlivestock.shared.domain.TelemetryPage<RumenMotilityLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable) {
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
    public List<RumenMotilityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit) {
        return jpaRepo.findByLivestockIdOrderByRecordedAtDesc(livestockId).stream()
                .limit(limit).map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<RumenMotilityLog> findByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to) {
        return jpaRepo.findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(deviceId, from, to)
                .stream().map(HealthMapper::toDomain).toList();
    }

    @Override
    public Optional<RumenMotilityLog> findLatestByDeviceIdWithRawCounter(Long deviceId) {
        return jpaRepo.findFirstByDeviceIdAndRawCounterIsNotNullOrderByRecordedAtDesc(deviceId)
                .map(HealthMapper::toDomain);
    }

    @Override
    public RumenMotilityLog save(RumenMotilityLog log) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(log)));
    }
}
