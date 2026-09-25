package com.smartlivestock.health.application.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.smartlivestock.health.application.dto.HealthDtos.AiAnomalySummary;
import com.smartlivestock.health.application.port.AnomalyScoreClient.AnomalyPrediction;
import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
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
 * Triggered by HealthAnomalyScheduler (moved out of processTelemetry after the
 * 2026-06-30 REQUIRES_NEW session-corruption incident — keep this call OUT of
 * telemetry-consuming transactions).
 * Dedup via Redis, calls ai-platform, writes anomaly_scores + health_snapshots AI columns,
 * manages source='AI' alerts (create-gated + hysteresis auto-resolve).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthAnomalyService {

    private final AnomalyScoreClient anomalyScoreClient;
    private final AnomalyScoreRepository anomalyScoreRepo;
    private final HealthSnapshotRepository snapshotRepo;
    private final RanchCommandPort ranchCommandPort;
    private final RanchQueryPort ranchQueryPort;
    private final RedisCacheService redis;
    private final ObjectMapper objectMapper;

    @Value("${ai.alert.threshold:0.7}")
    private double alertThreshold;

    /** Below this score lingering AI alerts auto-resolve (hysteresis vs alertThreshold). */
    @Value("${ai.alert.resolve-threshold:0.5}")
    private double resolveThreshold;

    @Value("${ai.dedup.ttl-minutes:60}")
    private int dedupTtlMinutes;

    /** alerts.source CHECK allows only ('RULE','AI','DATAGEN'); telemetrySource must NOT go here. */
    private static final String ALERT_SOURCE_AI = "AI";
    private static final String DEDUP_KEY_PREFIX = "ai:dedup:";

    /**
     * Assess a single livestock health anomaly via ai-platform.
     * Design SS3.1: dedup per livestock (30-60min window).
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public void assess(Long tenantId, Long farmId, Long livestockId) {
        assess(tenantId, farmId, livestockId, "UNKNOWN");
    }

    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public void assess(Long tenantId, Long farmId, Long livestockId, String telemetrySource) {
        try {
            doAssess(tenantId, farmId, livestockId, telemetrySource);
        } catch (Exception e) {
            log.warn("AI assess failed (suppressed, telemetry continues) for livestock [{}]: {}", livestockId, e.getMessage());
            // Do NOT rethrow — a REQUIRES_NEW transaction failure must never
            // corrupt a caller's transaction.
        }
    }

    private void doAssess(Long tenantId, Long farmId, Long livestockId, String telemetrySource) {
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
            return;  // degradation - rule engine continues, retried next poll
        }

        AnomalyPrediction pred = predictions.get(0);
        Instant now = Instant.now();
        BigDecimal scoreValue = BigDecimal.valueOf(pred.anomalyScore()).setScale(3, RoundingMode.HALF_UP);

        // 3. Persist anomaly_scores (skip near-zero rows to keep history meaningful)
        if (pred.anomalyScore() >= 0.001) {
            AnomalyScore score = new AnomalyScore();
            score.setTenantId(tenantId);
            score.setFarmId(farmId);
            score.setLivestockId(livestockId);
            score.setWindowStart(now.minus(Duration.ofHours(24)));
            score.setWindowEnd(now);
            score.setAnomalyScore(scoreValue);
            score.setAnomalyType(pred.anomalyType());
            Map<String, Object> contributions = new HashMap<>();
            contributions.put("stl", pred.stlContribution());
            contributions.put("cusum", pred.cusumContribution());
            contributions.put("joint", pred.jointContribution());
            score.setContributions(contributions);
            score.setCapabilityUsed(pred.capabilityUsed());
            score.setNEff(pred.nEff());
            score.setSource(telemetrySource);
            score.setModelMeta(parseModelMeta(pred.modelMetaJson()));
            anomalyScoreRepo.save(score);
        }

        // 4. Mirror current AI state onto health_snapshots (also when back to
        // normal, otherwise the overview keeps counting recovered livestock)
        snapshotRepo.findByLivestockId(livestockId).ifPresent(snap -> {
            snap.setAiAnomalyScore(scoreValue);
            snap.setAiAnomalyType(pred.anomalyType());
            snap.setAiAssessedAt(now);
            snapshotRepo.save(snap);
        });

        // 5. AI alert lifecycle: create once per type, auto-resolve with hysteresis
        if (pred.anomalyScore() >= alertThreshold) {
            String alertType = mapAnomalyTypeToAlertType(pred.anomalyType());
            String severity = pred.anomalyScore() >= 0.85 ? "CRITICAL" : "WARNING";
            if (!ranchQueryPort.hasActiveAlert(livestockId, alertType)) {
                ranchCommandPort.createAlert(new AlertInfo(
                        farmId, livestockId, alertType, severity,
                        buildAlertMessage(pred), ALERT_SOURCE_AI, "alert.ai.anomaly",
                        java.util.List.of(
                                pred.anomalyType(),
                                String.format("%.3f", pred.anomalyScore()),
                                String.valueOf(pred.nEff()))));
                log.info("Created {} alert for livestock [{}] (AI score={})",
                        alertType, livestockId, scoreValue);
            }
        } else if (pred.anomalyScore() < resolveThreshold) {
            ranchCommandPort.resolveAlertsBySource(livestockId, ALERT_SOURCE_AI);
        }

        // 6. Set dedup key — on every completed assessment (normal included),
        // so healthy livestock do not hammer ai-platform every poll
        redis.set(dedupKey, "1", Duration.ofMinutes(dedupTtlMinutes));
    }

    /**
     * Read-only query for embedding AI anomaly summary into detail responses.
     * Pure DB read (anomaly_scores table), does NOT call ai-platform.
     */
    public java.util.Optional<AiAnomalySummary> getLatestSummary(Long farmId, Long livestockId) {
        return anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
                .map(s -> new AiAnomalySummary(
                        s.getAnomalyScore().doubleValue(),
                        s.getAnomalyType(),
                        s.getNEff(),
                        s.getCapabilityUsed(),
                        s.getCreatedAt()
                ));
    }

    private Map<String, Object> parseModelMeta(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            log.debug("Failed to parse ai-platform model_meta: {}", e.getMessage());
            return null;
        }
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
