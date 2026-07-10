package com.smartlivestock.health.application.port;

import java.util.List;

/**
 * Port: Health -> ai-platform (Python FastAPI).
 * HTTP client with degradation. Returns empty list when ai-platform is unavailable.
 */
public interface AnomalyScoreClient {

    /**
     * Analyze livestock health anomaly via ai-platform.
     *
     * @param tenantId    tenant ID
     * @param farmId      farm ID
     * @param livestockIds list of livestock IDs to analyze
     * @param windowHours detection window in hours
     * @return list of predictions; empty list on degradation
     */
    List<AnomalyPrediction> analyze(Long tenantId, Long farmId, List<Long> livestockIds, int windowHours);

    /**
     * Single prediction result mirroring ai-platform PredictResponse.
     */
    record AnomalyPrediction(
            Long livestockId,
            double anomalyScore,
            String anomalyType,
            double stlContribution,
            double cusumContribution,
            double jointContribution,
            String capabilityUsed,
            int nEff,
            String modelMetaJson
    ) {}
}
