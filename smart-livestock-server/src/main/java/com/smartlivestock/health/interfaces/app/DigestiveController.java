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
public class DigestiveController {

    private final HealthApplicationService healthService;

    @GetMapping("/digestive")
    public ResponseEntity<ApiResponse<DigestiveListResponse>> getDigestiveList(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getDigestiveList(farmId)));
    }

    @GetMapping("/digestive/{livestockId}")
    public ResponseEntity<ApiResponse<DigestiveDetail>> getDigestiveDetail(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getDigestiveDetail(farmId, livestockId)));
    }

    @GetMapping("/digestive/{livestockId}/heatmap")
    public ResponseEntity<ApiResponse<List<IntensityCell>>> getIntensityHeatmap(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getIntensityHeatmap(farmId, livestockId)));
    }
}
