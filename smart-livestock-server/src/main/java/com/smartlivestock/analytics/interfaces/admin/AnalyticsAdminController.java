package com.smartlivestock.analytics.interfaces.admin;

import com.smartlivestock.analytics.application.dto.UsageOverviewDto;
import com.smartlivestock.analytics.application.dto.UsageTrendDto;
import com.smartlivestock.analytics.application.service.AnalyticsApplicationService;
import com.smartlivestock.analytics.application.service.UsageAggregationService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/analytics")
@RequiredArgsConstructor
public class AnalyticsAdminController {

    private final AnalyticsApplicationService analyticsService;
    private final UsageAggregationService aggregationService;

    @GetMapping("/tenants/{tenantId}/usage/overview")
    public ResponseEntity<ApiResponse<UsageOverviewDto>> getTenantOverview(
            @PathVariable Long tenantId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        UsageOverviewDto overview = analyticsService.getTenantOverview(tenantId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(overview));
    }

    @GetMapping("/tenants/{tenantId}/usage/trend")
    public ResponseEntity<ApiResponse<List<UsageTrendDto>>> getTenantTrend(
            @PathVariable Long tenantId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        List<UsageTrendDto> trend = analyticsService.getTenantTrend(tenantId, from, to);
        return ResponseEntity.ok(ApiResponse.ok(trend));
    }

    @GetMapping("/usage/overview")
    public ResponseEntity<ApiResponse<UsageOverviewDto>> getGlobalOverview(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        UsageOverviewDto overview = analyticsService.getGlobalOverview(from, to);
        return ResponseEntity.ok(ApiResponse.ok(overview));
    }

    @GetMapping("/usage/trend")
    public ResponseEntity<ApiResponse<List<UsageTrendDto>>> getGlobalTrend(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        List<UsageTrendDto> trend = analyticsService.getGlobalTrend(from, to);
        return ResponseEntity.ok(ApiResponse.ok(trend));
    }

    @PostMapping("/aggregate")
    public ResponseEntity<ApiResponse<String>> triggerAggregation(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        aggregationService.aggregateForDate(date);
        return ResponseEntity.ok(ApiResponse.ok("Aggregation completed for " + date));
    }
}
