package com.smartlivestock.analytics.interfaces;

import com.smartlivestock.analytics.application.dto.UsageOverviewDto;
import com.smartlivestock.analytics.application.dto.UsageTrendDto;
import com.smartlivestock.analytics.application.service.AnalyticsApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/analytics/usage")
@RequiredArgsConstructor
public class AnalyticsAppController {

    private final AnalyticsApplicationService analyticsService;

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<UsageOverviewDto>> getUsageOverview(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Long tenantId = TenantContext.getCurrentTenant();
        UsageOverviewDto overview = analyticsService.getTenantOverview(tenantId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(overview));
    }

    @GetMapping("/trend")
    public ResponseEntity<ApiResponse<List<UsageTrendDto>>> getUsageTrend(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Long tenantId = TenantContext.getCurrentTenant();
        List<UsageTrendDto> trend = analyticsService.getTenantTrend(tenantId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(trend));
    }

    @GetMapping("/api-keys/{apiKeyId}/overview")
    public ResponseEntity<ApiResponse<UsageOverviewDto>> getApiKeyUsageOverview(
            @PathVariable Long apiKeyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Long tenantId = TenantContext.getCurrentTenant();
        UsageOverviewDto overview = analyticsService.getApiKeyOverview(tenantId, apiKeyId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(overview));
    }

    @GetMapping("/api-keys/{apiKeyId}/trend")
    public ResponseEntity<ApiResponse<List<UsageTrendDto>>> getApiKeyUsageTrend(
            @PathVariable Long apiKeyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        Long tenantId = TenantContext.getCurrentTenant();
        List<UsageTrendDto> trend = analyticsService.getApiKeyTrend(tenantId, apiKeyId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(trend));
    }
}
