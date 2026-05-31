package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.*;
import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/health")
@RequiredArgsConstructor
public class HealthOverviewController {

    private final HealthApplicationService healthService;

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<HealthOverviewResponse>> getOverview(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getOverview(farmId)));
    }
}
