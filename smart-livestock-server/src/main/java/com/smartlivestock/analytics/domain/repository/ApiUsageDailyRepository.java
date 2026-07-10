package com.smartlivestock.analytics.domain.repository;

import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import java.time.LocalDate;
import java.util.List;

public interface ApiUsageDailyRepository {
    ApiUsageDaily save(ApiUsageDaily daily);
    List<ApiUsageDaily> findByTenantIdAndUsageDateBetween(Long tenantId, LocalDate from, LocalDate to);
    List<ApiUsageDaily> findByApiKeyIdAndUsageDateBetween(Long apiKeyId, LocalDate from, LocalDate to);
}
