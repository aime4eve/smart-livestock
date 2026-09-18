package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.LivestockPresenceService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Runtime threshold configuration for the presence scenarios (NIX-219 F4/F5).
 * Values live in memory and fall back to env defaults on restart — the cron
 * expression itself stays an env property (changing it requires re-registration).
 */
@RestController
@RequestMapping("/api/v1/admin/presence/thresholds")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class PresenceAdminController {

    private final LivestockPresenceService presenceService;

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> get() {
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "returnHomeThresholdM", presenceService.getReturnHomeThresholdM(),
                "outlierMadMultiplier", presenceService.getOutlierMadMultiplier(),
                "outlierMinDistanceM", presenceService.getOutlierMinDistanceM())));
    }

    public record ThresholdsUpdate(Double returnHomeThresholdM,
                                   Double outlierMadMultiplier,
                                   Double outlierMinDistanceM) {
    }

    @PutMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> update(
            @RequestBody ThresholdsUpdate request) {
        presenceService.updateThresholds(
                request.returnHomeThresholdM(),
                request.outlierMadMultiplier(),
                request.outlierMinDistanceM());
        return get();
    }
}
