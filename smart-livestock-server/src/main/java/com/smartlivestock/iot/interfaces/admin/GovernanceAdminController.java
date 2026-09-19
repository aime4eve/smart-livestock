package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.GpsDataGovernanceService;
import com.smartlivestock.iot.domain.model.GpsQualityFlagSummary;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

/**
 * Data-governance quality metrics (NIX-220). Read-only: per-rule/day totals and
 * worst-offender devices for the GPS validity rule set. Capsule rule sets will
 * join the same endpoint as they are registered.
 */
@RestController
@RequestMapping("/api/v1/admin/governance")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class GovernanceAdminController {

    private final GpsDataGovernanceService governanceService;

    @GetMapping("/gps-flags")
    public ResponseEntity<ApiResponse<Map<String, Object>>> gpsFlags(
            @RequestParam(defaultValue = "7") int days) {
        int windowDays = Math.max(1, Math.min(days, 90));
        Instant to = Instant.now();
        Instant from = to.minus(windowDays, ChronoUnit.DAYS);
        List<GpsQualityFlagSummary> byRuleDay = governanceService.summarize(from, to);
        List<GpsQualityFlagSummary> byDevice = governanceService.summarizeByDevice(from, to);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "from", from,
                "to", to,
                "byRuleDay", byRuleDay,
                "byDevice", byDevice.stream().limit(50).toList())));
    }
}
