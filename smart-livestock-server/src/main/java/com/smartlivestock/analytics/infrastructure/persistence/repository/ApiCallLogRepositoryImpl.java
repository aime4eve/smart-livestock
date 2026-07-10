package com.smartlivestock.analytics.infrastructure.persistence.repository;

import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.analytics.domain.repository.ApiCallLogRepository;
import com.smartlivestock.analytics.infrastructure.persistence.jpa.SpringDataApiCallLogRepository;
import com.smartlivestock.analytics.infrastructure.persistence.mapper.AnalyticsMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class ApiCallLogRepositoryImpl implements ApiCallLogRepository {
    private final SpringDataApiCallLogRepository springDataRepo;

    @Override
    public ApiCallLog save(ApiCallLog log) {
        return AnalyticsMapper.toDomain(springDataRepo.save(AnalyticsMapper.toJpa(log)));
    }

    @Override
    public void saveAll(List<ApiCallLog> logs) {
        springDataRepo.saveAll(logs.stream().map(AnalyticsMapper::toJpa).toList());
    }

    @Override
    public List<ApiCallLog> findByTenantIdAndRequestedAtBetween(Long tenantId, Instant from, Instant to) {
        return springDataRepo.findByTenantIdAndRequestedAtBetween(tenantId, from, to)
                .stream().map(AnalyticsMapper::toDomain).toList();
    }

    @Override
    public List<ApiCallLog> findByApiKeyIdAndRequestedAtBetween(Long apiKeyId, Instant from, Instant to) {
        return springDataRepo.findByApiKeyIdAndRequestedAtBetween(apiKeyId, from, to)
                .stream().map(AnalyticsMapper::toDomain).toList();
    }

    @Override
    public long countByTenantIdAndRequestedAtAfter(Long tenantId, Instant since) {
        return springDataRepo.countByTenantIdAndRequestedAtAfter(tenantId, since);
    }

    @Override
    public void deleteOlderThan(Instant cutoff) {
        springDataRepo.deleteByRequestedAtBefore(cutoff);
    }

    @Override
    public List<ApiCallLog> findAllByRequestedAtBetween(Instant from, Instant to) {
        return springDataRepo.findAllByRequestedAtBetween(from, to)
                .stream().map(AnalyticsMapper::toDomain).toList();
    }
}
