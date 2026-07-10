package com.smartlivestock.analytics.application.service;

import com.smartlivestock.analytics.application.dto.UsageOverviewDto;
import com.smartlivestock.analytics.application.dto.UsageTrendDto;
import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.domain.repository.ApiUsageDailyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AnalyticsApplicationService {

    private final ApiUsageDailyRepository usageDailyRepository;

    public UsageOverviewDto getTenantOverview(Long tenantId, LocalDate from, LocalDate to) {
        List<ApiUsageDaily> daily = usageDailyRepository.findByTenantIdAndUsageDateBetween(tenantId, from, to);
        return buildOverview(daily, from, to);
    }

    public UsageOverviewDto getApiKeyOverview(Long tenantId, Long apiKeyId, LocalDate from, LocalDate to) {
        List<ApiUsageDaily> daily = usageDailyRepository.findByApiKeyIdAndUsageDateBetween(apiKeyId, from, to)
                .stream().filter(d -> d.getTenantId().equals(tenantId)).toList();
        return buildOverview(daily, from, to);
    }

    public List<UsageTrendDto> getTenantTrend(Long tenantId, LocalDate from, LocalDate to) {
        return usageDailyRepository.findByTenantIdAndUsageDateBetween(tenantId, from, to)
                .stream()
                .map(d -> new UsageTrendDto(d.getUsageDate(), d.getTotalCalls(),
                        d.getSuccessCalls(), d.getErrorCalls(), d.getAvgResponseMs()))
                .toList();
    }

    public List<UsageTrendDto> getApiKeyTrend(Long tenantId, Long apiKeyId, LocalDate from, LocalDate to) {
        return usageDailyRepository.findByApiKeyIdAndUsageDateBetween(apiKeyId, from, to)
                .stream().filter(d -> d.getTenantId().equals(tenantId))
                .map(d -> new UsageTrendDto(d.getUsageDate(), d.getTotalCalls(),
                        d.getSuccessCalls(), d.getErrorCalls(), d.getAvgResponseMs()))
                .toList();
    }

    private UsageOverviewDto buildOverview(List<ApiUsageDaily> daily, LocalDate from, LocalDate to) {
        long totalCalls = daily.stream().mapToLong(ApiUsageDaily::getTotalCalls).sum();
        long successCalls = daily.stream().mapToLong(ApiUsageDaily::getSuccessCalls).sum();
        long errorCalls = daily.stream().mapToLong(ApiUsageDaily::getErrorCalls).sum();
        double avgResponseMs = daily.stream()
                .filter(d -> d.getAvgResponseMs() != null)
                .mapToInt(ApiUsageDaily::getAvgResponseMs)
                .average().orElse(0.0);
        return new UsageOverviewDto(totalCalls, successCalls, errorCalls, avgResponseMs, from, to);
    }
}
