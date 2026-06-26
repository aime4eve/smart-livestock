package com.smartlivestock.health.infrastructure.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * RestClient implementation of AnomalyScoreClient.
 * Calls ai-platform POST /ai/health/analyze. Degrades to empty list on any error.
 */
@Slf4j
@Component
public class RestAnomalyScoreClient implements AnomalyScoreClient {

    private final ObjectMapper objectMapper;

    @Value("${ai.platform.url:http://localhost:18000}")
    private String baseUrl;

    private RestClient restClient;

    public RestAnomalyScoreClient(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    void init() {
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
    }

    @Override
    public List<AnomalyPrediction> analyze(Long tenantId, Long farmId, List<Long> livestockIds, int windowHours) {
        if (livestockIds == null || livestockIds.isEmpty()) {
            return List.of();
        }
        try {
            Map<String, Object> body = Map.of(
                    "tenant_id", tenantId,
                    "farm_id", farmId,
                    "livestock_ids", livestockIds,
                    "window_hours", windowHours);

            JsonNode resp = restClient.post()
                    .uri("/ai/health/analyze")
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);

            return parseResults(resp);
        } catch (Exception e) {
            log.warn("ai-platform analyze failed (degrading to rule-only): {}", e.getMessage());
            return List.of();
        }
    }

    private List<AnomalyPrediction> parseResults(JsonNode resp) {
        List<AnomalyPrediction> results = new ArrayList<>();
        if (resp == null) {
            return results;
        }
        JsonNode arr = resp.path("results");
        if (!arr.isArray()) {
            return results;
        }
        for (JsonNode item : arr) {
            results.add(new AnomalyPrediction(
                    item.path("livestock_id").asLong(),
                    item.path("anomaly_score").asDouble(),
                    item.path("anomaly_type").asText("normal"),
                    item.path("contributions").path("stl").asDouble(0),
                    item.path("contributions").path("cusum").asDouble(0),
                    item.path("contributions").path("joint").asDouble(0),
                    item.path("capability_used").asText("none"),
                    item.path("n_eff").asInt(0),
                    item.path("model_meta").toString()));
        }
        return results;
    }
}
