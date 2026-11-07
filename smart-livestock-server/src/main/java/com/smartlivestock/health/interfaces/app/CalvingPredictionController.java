package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.dto.HealthDtos.CalvingPredictionListResponse;
import com.smartlivestock.health.application.service.CalvingPredictionQueryService;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Calving prediction list (NIX-389): latest calving_predictions row per
 * livestock, behind the calving_warning subscription gate. The route sits
 * under /livestock (not /health) per the ticket contract; the response shape
 * mirrors the estrus list style (items only).
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/livestock")
@RequiredArgsConstructor
public class CalvingPredictionController {

    private final CalvingPredictionQueryService queryService;

    @GetMapping("/calving-predictions")
    public ResponseEntity<ApiResponse<CalvingPredictionListResponse>> getCalvingPredictions(
            @PathVariable Long farmId,
            @RequestParam(defaultValue = "200") int limit) {
        return ResponseEntity.ok(ApiResponse.ok(queryService.getCalvingPredictions(farmId, limit)));
    }
}
