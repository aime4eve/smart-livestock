package com.smartlivestock.analytics.domain.repository;

import com.smartlivestock.analytics.domain.model.ApiCallLog;
import java.time.Instant;
import java.util.List;

public interface ApiCallLogRepository {
    ApiCallLog save(ApiCallLog log);
    void saveAll(List<ApiCallLog> logs);
    List<ApiCallLog> findByTenantIdAndRequestedAtBetween(Long tenantId, Instant from, Instant to);
    List<ApiCallLog> findByApiKeyIdAndRequestedAtBetween(Long apiKeyId, Instant from, Instant to);
    long countByTenantIdAndRequestedAtAfter(Long tenantId, Instant since);
    void deleteOlderThan(Instant cutoff);
    List<ApiCallLog> findAllByRequestedAtBetween(Instant from, Instant to);
}
