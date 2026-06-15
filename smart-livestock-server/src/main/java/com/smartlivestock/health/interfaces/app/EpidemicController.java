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
public class EpidemicController {

    private final HealthApplicationService healthService;

    @GetMapping("/epidemic")
    public ResponseEntity<ApiResponse<EpidemicResponse>> getEpidemicOverview(@PathVariable Long farmId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getEpidemicOverview(farmId)));
    }

    @GetMapping("/epidemic/contacts/{livestockId}")
    public ResponseEntity<ApiResponse<ContactNetworkResponse>> getContactNetwork(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        return ResponseEntity.ok(ApiResponse.ok(healthService.getContactNetwork(farmId, livestockId)));
    }

    @PostMapping("/epidemic/mark")
    public ResponseEntity<ApiResponse<Void>> markDiseased(
            @PathVariable Long farmId, @RequestBody MarkDiseaseRequest request) {
        healthService.markDiseased(farmId, request.livestockId(), request.diseaseType());
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @DeleteMapping("/epidemic/mark/{livestockId}")
    public ResponseEntity<ApiResponse<Void>> unmarkDiseased(
            @PathVariable Long farmId, @PathVariable Long livestockId) {
        healthService.unmarkDiseased(farmId, livestockId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
