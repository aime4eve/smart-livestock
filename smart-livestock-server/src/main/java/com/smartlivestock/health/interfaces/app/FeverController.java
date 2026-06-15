package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.*;
import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/farms/{farmId}/health")
@RequiredArgsConstructor
public class FeverController {

    private final HealthApplicationService healthService;

    @GetMapping("/fever")
    public ResponseEntity<ApiResponse<FeverListResponse>> getFeverList(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getFeverList(farmId)));
    }

    @GetMapping("/fever/{livestockId}")
    public ResponseEntity<ApiResponse<FeverDetail>> getFeverDetail(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getFeverDetail(farmId, livestockId)));
    }

    @GetMapping("/fever/{livestockId}/duration")
    public ResponseEntity<ApiResponse<List<DailyFeverHour>>> getFeverDurationChart(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getFeverDurationChart(farmId, livestockId)));
    }
}
