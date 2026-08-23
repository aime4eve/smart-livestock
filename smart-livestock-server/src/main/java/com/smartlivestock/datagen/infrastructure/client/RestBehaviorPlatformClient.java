package com.smartlivestock.datagen.infrastructure.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;
import com.smartlivestock.datagen.application.behavior.BehaviorPlatformClient;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformAnalysis;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformPrediction;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformTraining;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class RestBehaviorPlatformClient implements BehaviorPlatformClient {
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Value("${ai.platform.url:http://localhost:18000}")
    private String baseUrl;

    @Value("${ai.platform.behavior-timeout-ms:300000}")
    private int timeoutMs;

    public RestBehaviorPlatformClient(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .version(HttpClient.Version.HTTP_1_1)
                .build();
    }

    @Override
    public BehaviorPlatformTraining train(String datasetId, String modelName, String modelVersion,
                                          int minimumSupport, Integer randomSeed) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("dataset_id", datasetId);
        body.put("model_name", modelName);
        body.put("model_version", modelVersion);
        body.put("minimum_support", minimumSupport);
        if (randomSeed != null) {
            body.put("random_seed", randomSeed);
        }
        JsonNode response = post("/ai/behavior/train", body);
        return new BehaviorPlatformTraining(
                response.path("dataset_id").asText(),
                response.path("model_name").asText(),
                response.path("model_version").asText(),
                response.path("artifact_hash").asText(),
                objectMapper.convertValue(
                        response.path("manifest"),
                        new TypeReference<Map<String, Object>>() {}));
    }

    @Override
    public BehaviorPlatformAnalysis analyze(Long tenantId, Long farmId, String capability,
                                            String modelName, String modelVersion,
                                            List<BehaviorWindowJpaEntity> windows) {
        List<BehaviorPlatformPrediction> predictions = new ArrayList<>();
        List<Map<String, String>> errors = new ArrayList<>();
        int batchSize = 5000;
        for (int offset = 0; offset < windows.size(); offset += batchSize) {
            List<BehaviorWindowJpaEntity> batch =
                    windows.subList(offset, Math.min(offset + batchSize, windows.size()));
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("tenant_id", tenantId);
            body.put("farm_id", farmId);
            body.put("requested_capability", capability);
            if (modelName != null) body.put("model_name", modelName);
            if (modelVersion != null) body.put("model_version", modelVersion);
            body.put("windows", batch.stream().map(BehaviorPlatformClient::windowBody).toList());
            JsonNode response = post("/ai/behavior/analyze", body);

            for (JsonNode item : response.path("results")) {
                Map<String, Double> probabilities = new LinkedHashMap<>();
                item.path("probability_vector").fields().forEachRemaining(entry ->
                        probabilities.put(entry.getKey(), entry.getValue().asDouble()));
                Map<String, String> labels = new LinkedHashMap<>();
                item.path("predicted_labels").fields().forEachRemaining(entry ->
                        labels.put(entry.getKey(), entry.getValue().asText()));
                predictions.add(new BehaviorPlatformPrediction(
                        item.path("window_id").asText(),
                        item.path("dominant_behavior").asText(),
                        probabilities,
                        labels,
                        item.path("capability_level").asText(),
                        item.path("model_name").asText(),
                        item.path("model_version").asText()));
            }
            for (JsonNode item : response.path("errors")) {
                Map<String, String> error = new LinkedHashMap<>();
                error.put("window_id", item.path("window_id").asText());
                error.put("message", item.path("message").asText());
                errors.add(error);
            }
        }
        return new BehaviorPlatformAnalysis(predictions, errors);
    }

    private JsonNode post(String path, Map<String, Object> body) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl + path))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            objectMapper.writeValueAsString(body)))
                    .timeout(Duration.ofMillis(timeoutMs))
                    .build();
            HttpResponse<String> response =
                    httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ApiException(
                        ErrorCode.STATE_CONFLICT,
                        "error.datagen.behaviorPlatformFailed");
            }
            return objectMapper.readTree(response.body());
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.warn("ai-platform behavior request failed: {}", e.getMessage());
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorPlatformFailed");
        }
    }
}
