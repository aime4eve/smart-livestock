package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.smartlivestock.health.application.port.AnomalyScoreClient.AnomalyPrediction;
import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.cache.RedisCacheService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI anomaly detection orchestration (Phase A design SS3.1 method A).
 * Called from HealthApplicationService.processTelemetry() tail.
 * Dedup via Redis, calls ai-platform, writes anomaly_scores + health_snapshots AI columns,
 * raises AI alerts when score exceeds threshold.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthAnomalyService {

    private final AnomalyScoreClient anomalyScoreClient;
    private final AnomalyScoreRepository anomalyScoreRepo;
    private final HealthSnapshotRepository snapshotRepo;
    private final RanchCommandPort ranchCommandPort;
    private final RedisCacheService redis;

    @Value("${ai.alert.threshold:0.7}")
    private double alertThreshold;

    @Value("${ai.dedup.ttl-minutes:60}")
    private int dedupTtlMinutes;

    private static final String DEDUP_KEY_PREFIX = "ai:dedup:";

    /**
     * Assess a single livestock health anomaly via ai-platform.
     * Design SS3.1: dedup per livestock (30-60min window).
     */
    @Transactional
    public void assess(Long tenantId, Long farmId, Long livestockId) {
        // 1. Dedup: skip if assessed recently
        String dedupKey = DEDUP_KEY_PREFIX + livestockId;
        if (redis.get(dedupKey) != null) {
            log.debug("AI dedup skip for livestock [{}]", livestockId);
            return;
        }

        // 2. Call ai-platform (degrades to empty if unavailable)
        List<AnomalyPrediction> predictions = anomalyScoreClient.analyze(
                tenantId, farmId, List.of(livestockId), 24);
        if (predictions.isEmpty()) {
            return;  // degradation - rule engine continues
        }

        AnomalyPrediction pred = predictions.get(0);
        if (pred.anomalyScore() < 0.001) {
            return; // normal, skip persistence
        }

        // 3. Write anomaly_scores
        Instant now = Instant.now();
        AnomalyScore score = new AnomalyScore();
        score.setTenantId(tenantId);
        score.setFarmId(farmId);
        score.setLivestockId(livestockId);
        score.setWindowStart(now.minus(Duration.ofHours(24)));
        score.setWindowEnd(now);
        score.setAnomalyScore(BigDecimal.valueOf(pred.anomalyScore()).setScale(3, RoundingMode.HALF_UP));
        score.setAnomalyType(pred.anomalyType());
        Map<String, Object> contributions = new HashMap<>();
        contributions.put("stl", pred.stlContribution());
        contributions.put("cusum", pred.cusumContribution());
        contributions.put("joint", pred.jointContribution());
        score.setContributions(contributions);
        score.setCapabilityUsed(pred.capabilityUsed());
        score.setNEff(pred.nEff());
        anomalyScoreRepo.save(score);

        // 4. Update health_snapshots AI columns
        snapshotRepo.findByLivestockId(livestockId).ifPresent(snap -> {
            snap.setAiAnomalyScore(score.getAnomalyScore());
            snap.setAiAnomalyType(pred.anomalyType());
            snap.setAiAssessedAt(now);
            snapshotRepo.save(snap);
        });

        // 5. Raise AI alert if over threshold
        if (pred.anomalyScore() >= alertThreshold) {
            String alertType = mapAnomalyTypeToAlertType(pred.anomalyType());
            String severity = pred.anomalyScore() >= 0.85 ? "CRITICAL" : "WARNING";
            ranchCommandPort.createAlert(new AlertInfo(
                    farmId, livestockId, alertType, severity,
                    buildAlertMessage(pred), "AI"));
        }

        // 6. Set dedup key
        redis.set(dedupKey, "1", Duration.ofMinutes(dedupTtlMinutes));
    }

    private String mapAnomalyTypeToAlertType(String anomalyType) {
        return switch (anomalyType) {
            case "abrupt_change", "circadian_disruption" -> "TEMPERATURE_ABNORMAL";
            case "multivariate" -> "AI_ANOMALY";
            default -> "AI_ANOMALY";
        };
    }

    private String buildAlertMessage(AnomalyPrediction pred) {
        return String.format("AI anomaly: %s (score=%.3f, n_eff=%d)",
                pred.anomalyType(), pred.anomalyScore(), pred.nEff());
    }
}
