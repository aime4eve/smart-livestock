package com.smartlivestock.health.infrastructure.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.application.port.AnomalyScoreClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class RestAnomalyScoreClient implements AnomalyScoreClient {

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Value("${ai.platform.url:http://localhost:18000}")
    private String baseUrl;

    @Value("${ai.platform.timeout-ms:5000}")
    private int timeoutMs;

    public RestAnomalyScoreClient(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
       this.httpClient = HttpClient.newBuilder()
               .connectTimeout(Duration.ofSeconds(5))
                .version(HttpClient.Version.HTTP_1_1)
               .build();
    }

    @Override
    public List<AnomalyPrediction> analyze(Long tenantId, Long farmId, List<Long> livestockIds, int windowHours) {
        if (livestockIds.isEmpty()) {
            return List.of();
        }
        try {
            Map<String, Object> body = Map.of(
                    "tenant_id", tenantId,
                    "farm_id", farmId,
                    "livestock_ids", livestockIds,
                    "window_hours", windowHours);

           String jsonBody = objectMapper.writeValueAsString(body);
            log.info("ai-platform request: url={}/ai/health/analyze, body={}", baseUrl, jsonBody);

           HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + "/ai/health/analyze"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                    .timeout(Duration.ofMillis(timeoutMs))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                log.warn("ai-platform returned {}: {}", response.statusCode(), response.body());
                return List.of();
            }

            JsonNode resp = objectMapper.readTree(response.body());
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
