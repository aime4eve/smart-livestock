package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.shared.common.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * API endpoints for AI anomaly detection results.
 * Farm-scoped: SecurityConfig FarmScopeResolver resolves activeFarmId.
 */
@RestController
@RequestMapping("/api/v1/farms/{farmId}/health/anomaly")
@RequiredArgsConstructor
public class AnomalyController {

    private final AnomalyScoreRepository anomalyScoreRepo;

    /** Latest AI anomaly score for a livestock. */
    @GetMapping("/{livestockId}")
    public ResponseEntity<ApiResponse<AnomalyScore>> getLatestAnomaly(@PathVariable Long farmId,
                                                @PathVariable Long livestockId) {
        // Envelope + plain map default keep ApiClient.farmGet's unwrap contract
        // (a bare entity/array response made the Flutter chip/chart silently fail).
        return ResponseEntity.ok(ApiResponse.ok(
                anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
                        .orElseGet(() -> defaultEmpty(livestockId))));
    }

    /** History of AI anomaly scores for a livestock. */
    @GetMapping("/{livestockId}/history")
    public ResponseEntity<ApiResponse<List<AnomalyScore>>> getAnomalyHistory(@PathVariable Long farmId,
                                                 @PathVariable Long livestockId,
                                                 @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(ApiResponse.ok(
                anomalyScoreRepo.findByFarmIdAndLivestockId(farmId, livestockId, limit)));
    }

    private static AnomalyScore defaultEmpty(Long livestockId) {
        AnomalyScore score = new AnomalyScore();
        score.setFarmId(null);
        score.setLivestockId(livestockId);
        score.setAnomalyScore(java.math.BigDecimal.ZERO);
        score.setAnomalyType("normal");
        return score;
    }
}
