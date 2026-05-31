package com.smartlivestock.analytics.infrastructure.persistence.mapper;

import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.infrastructure.persistence.entity.ApiCallLogJpaEntity;
import com.smartlivestock.analytics.infrastructure.persistence.entity.ApiUsageDailyJpaEntity;

public final class AnalyticsMapper {
    private AnalyticsMapper() {}

    public static ApiCallLogJpaEntity toJpa(ApiCallLog d) {
        ApiCallLogJpaEntity e = new ApiCallLogJpaEntity();
        e.setId(d.getId());
        e.setApiKeyId(d.getApiKeyId());
        e.setTenantId(d.getTenantId());
        e.setEndpoint(d.getEndpoint());
        e.setMethod(d.getMethod());
        e.setStatusCode(d.getStatusCode());
        e.setResponseTimeMs(d.getResponseTimeMs());
        e.setIpAddress(d.getIpAddress());
        e.setUserAgent(d.getUserAgent());
        e.setFarmId(d.getFarmId());
        e.setRequestedAt(d.getRequestedAt());
        return e;
    }

    public static ApiCallLog toDomain(ApiCallLogJpaEntity e) {
        ApiCallLog d = new ApiCallLog();
        d.setId(e.getId());
        d.setApiKeyId(e.getApiKeyId());
        d.setTenantId(e.getTenantId());
        d.setEndpoint(e.getEndpoint());
        d.setMethod(e.getMethod());
        d.setStatusCode(e.getStatusCode());
        d.setResponseTimeMs(e.getResponseTimeMs());
        d.setIpAddress(e.getIpAddress());
        d.setUserAgent(e.getUserAgent());
        d.setFarmId(e.getFarmId());
        d.setRequestedAt(e.getRequestedAt());
        return d;
    }

    public static ApiUsageDailyJpaEntity toJpa(ApiUsageDaily d) {
        ApiUsageDailyJpaEntity e = new ApiUsageDailyJpaEntity();
        e.setId(d.getId());
        e.setApiKeyId(d.getApiKeyId());
        e.setTenantId(d.getTenantId());
        e.setUsageDate(d.getUsageDate());
        e.setTotalCalls(d.getTotalCalls());
        e.setSuccessCalls(d.getSuccessCalls());
        e.setErrorCalls(d.getErrorCalls());
        e.setAvgResponseMs(d.getAvgResponseMs());
        e.setP95ResponseMs(d.getP95ResponseMs());
        e.setTopEndpoints(d.getTopEndpoints());
        return e;
    }

    public static ApiUsageDaily toDomain(ApiUsageDailyJpaEntity e) {
        ApiUsageDaily d = new ApiUsageDaily();
        d.setId(e.getId());
        d.setApiKeyId(e.getApiKeyId());
        d.setTenantId(e.getTenantId());
        d.setUsageDate(e.getUsageDate());
        d.setTotalCalls(e.getTotalCalls());
        d.setSuccessCalls(e.getSuccessCalls());
        d.setErrorCalls(e.getErrorCalls());
        d.setAvgResponseMs(e.getAvgResponseMs());
        d.setP95ResponseMs(e.getP95ResponseMs());
        d.setTopEndpoints(e.getTopEndpoints());
        return d;
    }
}
