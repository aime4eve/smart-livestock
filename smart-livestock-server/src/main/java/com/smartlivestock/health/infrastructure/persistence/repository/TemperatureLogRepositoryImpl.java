package com.smartlivestock.health.infrastructure.persistence.repository;

import com.smartlivestock.shared.domain.TelemetryPage;
import com.smartlivestock.health.domain.model.DailyTemperatureStat;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.mapper.HealthMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
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
    public TelemetryPage<TemperatureLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize) {
        return toPage(jpaRepo.findByLivestockIdAndRecordedAtBetweenOrderByRecordedAtAsc(
                        livestockId, from, to, PageRequest.of(Math.max(0, page - 1), pageSize))
                .map(HealthMapper::toDomain), page, pageSize);
    }

    @Override
    public TelemetryPage<TemperatureLog> findPageByDevice(Long deviceId, Instant from, Instant to, int page, int pageSize) {
        return toPage(jpaRepo.findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(
                        deviceId, from, to, PageRequest.of(Math.max(0, page - 1), pageSize))
                .map(HealthMapper::toDomain), page, pageSize);
    }


    @Override
    public com.smartlivestock.shared.domain.TelemetryPage<TemperatureLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable) {
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
    public List<TemperatureLog> findByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to) {
        return jpaRepo.findByDeviceIdAndRecordedAtBetweenOrderByRecordedAtAsc(deviceId, from, to)
                .stream().map(HealthMapper::toDomain).toList();
    }

    @Override
    public List<DailyTemperatureStat> aggregateDailyStats(List<Long> livestockIds, Instant since) {
        if (livestockIds == null || livestockIds.isEmpty()) {
            return List.of();
        }
        return jpaRepo.aggregateDailyStatsRows(livestockIds, since).stream()
                .map(row -> new DailyTemperatureStat(
                        (String) row[0],
                        row[1] != null ? new java.math.BigDecimal(((Number) row[1]).doubleValue()) : null,
                        ((Number) row[2]).longValue(),
                        ((Number) row[3]).longValue()))
                .toList();
    }

    @Override
    public boolean existsByDeviceIdAndRecordedAtAndSource(
            Long deviceId, Instant recordedAt, String source) {
        return jpaRepo.existsByDeviceIdAndRecordedAtAndSource(deviceId, recordedAt, source);
    }

    @Override
    public TemperatureLog save(TemperatureLog log) {
        return HealthMapper.toDomain(jpaRepo.save(HealthMapper.toJpa(log)));
    }
}
