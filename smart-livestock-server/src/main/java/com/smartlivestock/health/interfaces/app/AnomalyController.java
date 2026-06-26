package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
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
@RequestMapping("/api/v1/health/anomaly")
@RequiredArgsConstructor
public class AnomalyController {

    private final AnomalyScoreRepository anomalyScoreRepo;
    private final HealthSnapshotRepository snapshotRepo;

    /** Latest AI anomaly score for a livestock. */
    @GetMapping("/{livestockId}")
    public ResponseEntity<?> getLatestAnomaly(@PathVariable Long livestockId,
                                                @RequestParam(defaultValue = "1") Long farmId) {
        return anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.ok(Map.of("anomalyScore", 0.0, "anomalyType", "normal")));
    }

    /** History of AI anomaly scores for a livestock. */
    @GetMapping("/{livestockId}/history")
    public ResponseEntity<?> getAnomalyHistory(@PathVariable Long livestockId,
                                                 @RequestParam(defaultValue = "1") Long farmId,
                                                 @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(anomalyScoreRepo.findByFarmIdAndLivestockId(farmId, livestockId, limit));
    }
}
