package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorAnalyzeRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorModelTrainRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformAnalysis;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformPrediction;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformTraining;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import com.smartlivestock.datagen.domain.service.BehaviorFeatureValidator;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorDatasetJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorPredictionJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorDatasetJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorPredictionJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BehaviorAnalysisOrchestrationService {
    private final BehaviorPlatformClient platformClient;
    private final BehaviorFeatureValidator featureValidator;
    private final DatagenFarmAccessService farmAccessService;
    private final BehaviorDatasetJpaRepository datasetRepository;
    private final BehaviorEpisodeJpaRepository episodeRepository;
    private final BehaviorWindowJpaRepository windowRepository;
    private final BehaviorPredictionJpaRepository predictionRepository;

    @Transactional
    public BehaviorPlatformTraining train(
            UUID datasetId,
            BehaviorModelTrainRequest request,
            DatagenOperatorContext operator) {
        BehaviorDatasetJpaEntity dataset = accessibleDataset(datasetId, operator);
        if (!"DATAGEN".equals(dataset.getDataSource())) {
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorSyntheticOnly");
        }
        if (request == null || !"L2_SUPERVISED".equals(request.requestedCapability())
                || blank(request.modelName()) || blank(request.modelVersion())) {
            throw new ApiException(
                    ErrorCode.VALIDATION_ERROR,
                    "error.datagen.behaviorInvalidRequest");
        }
        return platformClient.train(
                datasetId.toString(),
                request.modelName(),
                request.modelVersion(),
                request.minimumSupport() == null ? 1 : request.minimumSupport(),
                request.randomSeed());
    }

    @Transactional
    public AnalysisResult analyze(
            UUID datasetId,
            BehaviorAnalyzeRequest request,
            DatagenOperatorContext operator) {
        BehaviorDatasetJpaEntity dataset = accessibleDataset(datasetId, operator);
        List<BehaviorWindowJpaEntity> windows = windowRepository
                .findByDatasetIdOrderByWindowStartAsc(datasetId).stream()
                .filter(BehaviorWindowJpaEntity::isModelCompatible)
                .toList();
        if (windows.isEmpty()) {
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorNoCompatibleWindows");
        }
        Map<Long, List<BehaviorWindowJpaEntity>> byFarm = windows.stream()
                .collect(Collectors.groupingBy(BehaviorWindowJpaEntity::getFarmId));
        if (byFarm.size() != 1 || windows.stream().map(BehaviorWindowJpaEntity::getTenantId)
                .distinct().count() != 1) {
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorMixedScope");
        }

        String capability = request != null && !blank(request.requestedCapability())
                ? request.requestedCapability()
                : "L1_RULE";
        String modelName = request == null ? null : request.modelName();
        String modelVersion = request == null ? null : request.modelVersion();
        if ("L2_SUPERVISED".equals(capability) && (blank(modelName) || blank(modelVersion))) {
            throw new ApiException(
                    ErrorCode.VALIDATION_ERROR,
                    "error.datagen.behaviorInvalidRequest");
        }

        Long tenantId = windows.get(0).getTenantId();
        Long farmId = windows.get(0).getFarmId();
        for (BehaviorWindowJpaEntity window : windows) {
            featureValidator.validate(
                    BehaviorFeatureContract.v1(),
                    window.getFeatures(),
                    InputQuality.valueOf(window.getInputQuality()));
        }
        BehaviorPlatformAnalysis analysis = platformClient.analyze(
                tenantId, farmId, capability, modelName, modelVersion, windows);
        if (!analysis.errors().isEmpty()) {
            log.warn("ai-platform behavior prediction rejected windows: {}", analysis.errors());
            throw new ApiException(
                    ErrorCode.VALIDATION_ERROR,
                    "error.datagen.behaviorPredictionRejected");
        }
        if (analysis.results().size() != windows.size()) {
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorPredictionMismatch");
        }

        Map<String, BehaviorWindowJpaEntity> windowById = windows.stream().collect(
                Collectors.toMap(window -> window.getId().toString(), window -> window));
        String effectiveModelName = "L1_RULE".equals(capability) ? "behavior-rules" : modelName;
        String effectiveModelVersion = "L1_RULE".equals(capability) ? "v1" : modelVersion;
        Map<UUID, BehaviorPredictionJpaEntity> existing = predictionRepository
                .findByWindowIdInAndModelNameAndModelVersion(
                        windows.stream().map(BehaviorWindowJpaEntity::getId).toList(),
                        effectiveModelName,
                        effectiveModelVersion)
                .stream()
                .collect(Collectors.toMap(
                        BehaviorPredictionJpaEntity::getWindowId,
                        prediction -> prediction));
        int saved = 0;
        for (BehaviorPlatformPrediction result : analysis.results()) {
            BehaviorWindowJpaEntity window = windowById.get(result.windowId());
            if (window == null) {
                throw new ApiException(
                        ErrorCode.STATE_CONFLICT,
                        "error.datagen.behaviorPredictionMismatch");
            }
            upsert(window, result, existing.get(window.getId()));
            saved++;
        }
        return new AnalysisResult(datasetId, capability, saved);
    }

    private BehaviorDatasetJpaEntity accessibleDataset(
            UUID datasetId,
            DatagenOperatorContext operator) {
        BehaviorDatasetJpaEntity dataset = datasetRepository.findById(datasetId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND,
                        "error.datagen.behaviorDatasetNotFound",
                        new Object[]{datasetId}));
        episodeRepository.findByDatasetIdOrderByStartAtAsc(datasetId).stream()
                .map(BehaviorEpisodeJpaEntity::getFarmId)
                .distinct()
                .forEach(farmId -> farmAccessService.requireAccessibleFarm(farmId, operator));
        return dataset;
    }

    private void upsert(
            BehaviorWindowJpaEntity window,
            BehaviorPlatformPrediction result,
            BehaviorPredictionJpaEntity existing) {
        BehaviorPredictionJpaEntity entity = existing != null ? existing
                : new BehaviorPredictionJpaEntity();
        if (existing == null) {
            entity.setId(deterministicId(window.getDatasetId() + ":" + window.getId()
                    + ":" + result.modelName() + ":" + result.modelVersion()));
            entity.setWindowId(window.getId());
            entity.setCreatedAt(Instant.now());
        }
        entity.setModelName(result.modelName());
        entity.setModelVersion(result.modelVersion());
        entity.setPredictedDominantBehavior(result.dominantBehavior());
        entity.setDominantProbability(BigDecimal.valueOf(
                result.probabilityVector().getOrDefault(result.dominantBehavior(), 0.0)));
        entity.setPredictedLabels(new LinkedHashMap<>(result.predictedLabels()));
        entity.setProbabilityVector(new LinkedHashMap<>(result.probabilityVector()));
        entity.setCapabilityLevel(result.capabilityLevel());
        entity.setPredictedAt(Instant.now());
        predictionRepository.save(entity);
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private UUID deterministicId(String value) {
        return UUID.nameUUIDFromBytes(value.getBytes(StandardCharsets.UTF_8));
    }

    public record AnalysisResult(
            UUID datasetId,
            String capabilityLevel,
            int predictionCount) {
    }
}
