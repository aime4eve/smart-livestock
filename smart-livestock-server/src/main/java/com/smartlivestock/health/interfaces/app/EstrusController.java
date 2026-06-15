package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.*;
import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/health")
@RequiredArgsConstructor
public class EstrusController {

    private final HealthApplicationService healthService;

    @GetMapping("/estrus")
    public ResponseEntity<ApiResponse<EstrusListResponse>> getEstrusList(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getEstrusList(farmId)));
    }

    @GetMapping("/estrus/{livestockId}")
    public ResponseEntity<ApiResponse<EstrusDetail>> getEstrusDetail(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getEstrusDetail(farmId, livestockId)));
    }

    @GetMapping("/estrus/{livestockId}/activity")
    public ResponseEntity<ApiResponse<ActivityComparisonData>> getActivityComparison(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getActivityComparison(farmId, livestockId)));
    }
}
