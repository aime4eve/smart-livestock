package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetGenerateRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetStatusDto;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorDataSource;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorDatasetSplit;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorDatasetStatus;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedEpisode;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedWindow;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGenerationManifest;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelSource;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorTransitionMatrix;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import com.smartlivestock.datagen.domain.model.behavior.SamplingMode;
import com.smartlivestock.datagen.domain.service.BehaviorFeatureValidator;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorDatasetJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeSplitAssignmentJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorFeatureContractJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorLivestockSplitAssignmentJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowLabelJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorDatasetJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeSplitAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeSplitId;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorLivestockSplitAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorLivestockSplitId;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowLabelJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BehaviorDatasetPersistenceService {
    private static final int MAX_SUBJECTS = 50;
    private static final int MAX_WINDOWS = 20_000;

    private final BehaviorGenerationService generationService;
    private final BehaviorDatasetCanonicalizer canonicalizer;
    private final BehaviorFeatureValidator featureValidator;
    private final DatagenFarmAccessService farmAccessService;
    private final BehaviorFeatureContractJpaRepository contractRepository;
    private final BehaviorDatasetJpaRepository datasetRepository;
    private final BehaviorEpisodeJpaRepository episodeRepository;
    private final BehaviorLivestockSplitAssignmentJpaRepository livestockSplitRepository;
    private final BehaviorEpisodeSplitAssignmentJpaRepository episodeSplitRepository;
    private final BehaviorWindowJpaRepository windowRepository;
    private final BehaviorWindowLabelJpaRepository labelRepository;

    @Transactional
    public BehaviorDatasetStatusDto generate(
            BehaviorDatasetGenerateRequest request,
            DatagenOperatorContext operator) {
        try {
            BehaviorScenarioDefinition scenario = scenario(request, operator);
            String definitionDigest = canonicalizer.scenarioDigest(scenario);
            return datasetRepository.findByDefinitionDigest(definitionDigest)
                    .map(existing -> inspect(existing.getId(), operator, true))
                    .orElseGet(() -> generateAndPersist(scenario, definitionDigest, operator));
        } catch (IllegalArgumentException e) {
            throw new ApiException(
                    ErrorCode.VALIDATION_ERROR,
                    "error.datagen.behaviorInvalidRequest");
        }
    }

    @Transactional(readOnly = true)
    public BehaviorDatasetStatusDto inspect(UUID datasetId, DatagenOperatorContext operator) {
        return inspect(datasetId, operator, false);
    }

    private BehaviorDatasetStatusDto inspect(
            UUID datasetId,
            DatagenOperatorContext operator,
            boolean alreadyExists) {
        BehaviorDatasetJpaEntity dataset = datasetRepository.findById(datasetId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND,
                        "error.datagen.behaviorDatasetNotFound",
                        new Object[]{datasetId}));
        List<BehaviorEpisodeJpaEntity> episodes =
                episodeRepository.findByDatasetIdOrderByStartAtAsc(datasetId);
        episodes.stream().map(BehaviorEpisodeJpaEntity::getFarmId).distinct()
                .forEach(farmId -> farmAccessService.requireAccessibleFarm(farmId, operator));
        List<BehaviorWindowJpaEntity> windows =
                windowRepository.findByDatasetIdOrderByWindowStartAsc(datasetId);
        List<BehaviorWindowLabelJpaEntity> labels = labelsFor(windows);
        Map<UUID, String> episodeSplits = episodeSplitRepository.findByDatasetId(datasetId).stream()
                .collect(Collectors.toMap(
                        item -> item.getId().getEpisodeId(),
                        item -> item.getDatasetSplit()));

        Map<String, Long> splitCounts = windows.stream()
                .collect(Collectors.groupingBy(
                        window -> episodeSplits.getOrDefault(window.getEpisodeId(), "UNASSIGNED"),
                        Collectors.counting()));
        Map<String, Long> dominantCounts = windows.stream()
                .collect(Collectors.groupingBy(
                        BehaviorWindowJpaEntity::getDominantBehavior,
                        Collectors.counting()));
        Map<String, Long> qualityCounts = windows.stream()
                .collect(Collectors.groupingBy(
                        BehaviorWindowJpaEntity::getInputQuality,
                        Collectors.counting()));

        return new BehaviorDatasetStatusDto(
                dataset.getId(),
                dataset.getScenarioId(),
                dataset.getSeed(),
                dataset.getGeneratorVersion(),
                dataset.getDataSource(),
                dataset.getStatus(),
                dataset.getStartAt(),
                dataset.getEndAt(),
                episodes.size(),
                windows.size(),
                labels.size(),
                splitCounts,
                dominantCounts,
                qualityCounts,
                alreadyExists);
    }

    private BehaviorDatasetStatusDto generateAndPersist(
            BehaviorScenarioDefinition scenario,
            String definitionDigest,
            DatagenOperatorContext operator) {
        var contract = contractRepository.findById(
                        com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract.VERSION_V1)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.STATE_CONFLICT,
                        "error.datagen.behaviorContractMissing"));
        BehaviorGeneratedDataset generated = generationService.generate(scenario);
        featureValidator.assertCompatible(
                com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract.v1(),
                generated.manifest().featureVersion(),
                generated.manifest().featureSchemaHash());
        if (!contract.getSchemaHash().equals(generated.manifest().featureSchemaHash())) {
            throw new ApiException(
                    ErrorCode.STATE_CONFLICT,
                    "error.datagen.behaviorContractMismatch");
        }

        BehaviorGenerationManifest manifest = generated.manifest();
        BehaviorDatasetJpaEntity dataset = new BehaviorDatasetJpaEntity();
        dataset.setId(manifest.datasetId());
        dataset.setScenarioId(manifest.scenarioId());
        dataset.setSeed(manifest.seed());
        dataset.setGeneratorVersion(manifest.generatorVersion());
        dataset.setDataSource(BehaviorDataSource.DATAGEN.name());
        dataset.setStatus(BehaviorDatasetStatus.READY.name());
        dataset.setDefinitionDigest(definitionDigest);
        dataset.setManifest(manifestMap(manifest));
        dataset.setStartAt(manifest.startAt());
        dataset.setEndAt(manifest.endAt());
        dataset.setCreatedAt(Instant.now());
        datasetRepository.saveAndFlush(dataset);

        List<BehaviorEpisodeJpaEntity> episodes = generated.episodes().stream()
                .map(episode -> episodeEntity(manifest.datasetId(), episode))
                .toList();
        episodeRepository.saveAll(episodes);

        Map<Long, BehaviorDatasetSplit> livestockSplits = generated.episodes().stream()
                .map(episode -> episode.subject().livestockId())
                .distinct()
                .collect(Collectors.toMap(livestockId -> livestockId, this::splitFor));
        livestockSplitRepository.saveAll(livestockSplits.entrySet().stream()
                .map(entry -> livestockSplitEntity(
                        manifest.datasetId(), entry.getKey(), entry.getValue(), operator))
                .toList());
        Map<UUID, BehaviorDatasetSplit> episodeSplits = generated.episodes().stream()
                .collect(Collectors.toMap(
                        BehaviorGeneratedEpisode::id,
                        episode -> livestockSplits.get(episode.subject().livestockId())));
        episodeSplitRepository.saveAll(episodeSplits.entrySet().stream()
                .map(entry -> episodeSplitEntity(
                        manifest.datasetId(), entry.getKey(), entry.getValue(), operator))
                .toList());

        List<BehaviorWindowJpaEntity> windows = new ArrayList<>();
        List<BehaviorWindowLabelJpaEntity> labels = new ArrayList<>();
        for (BehaviorGeneratedWindow generatedWindow : generated.windows()) {
            featureValidator.validate(
                    com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract.v1(),
                    generatedWindow.feature().values(),
                    generatedWindow.inputQuality());
            generatedWindow.labels().forEach((facet, value) ->
                    featureValidator.validateLabel(facet, value, generatedWindow.inputQuality()));

            BehaviorWindowJpaEntity window = windowEntity(manifest.datasetId(), generatedWindow);
            windows.add(window);
            generatedWindow.labels().forEach((facet, value) ->
                    labels.add(labelEntity(window.getId(), facet, value)));
        }
        windowRepository.saveAll(windows);
        labelRepository.saveAll(labels);
        return inspect(manifest.datasetId(), operator, false);
    }

    private BehaviorScenarioDefinition scenario(
            BehaviorDatasetGenerateRequest request,
            DatagenOperatorContext operator) {
        if (request == null || request.subjects() == null) {
            throw new IllegalArgumentException("Request is incomplete");
        }
        if (request.subjects().size() > MAX_SUBJECTS) {
            throw new IllegalArgumentException("Too many subjects");
        }
        List<BehaviorSubject> subjects = request.subjects().stream()
                .map(this::subject)
                .toList();
        subjects.stream().map(BehaviorSubject::farmId).distinct()
                .forEach(farmId -> farmAccessService.requireAccessibleFarm(farmId, operator));

        List<Double> initialWeights = request.initialWeights() == null
                ? List.of(4.0, 3.0, 2.0, 1.0, 0.2)
                : request.initialWeights();
        BehaviorDatasetGenerateRequest.RealismRequest requestedRealism =
                request.realism() == null
                        ? new BehaviorDatasetGenerateRequest.RealismRequest(null, null, null, null)
                        : request.realism();
        BehaviorRealismProfile realism = new BehaviorRealismProfile(
                requestedRealism.noiseStdDevG() == null ? 0.003 : requestedRealism.noiseStdDevG(),
                requestedRealism.sampleDropoutRate() == null ? 0.01 : requestedRealism.sampleDropoutRate(),
                requestedRealism.missingWindowRate() == null ? 0.02 : requestedRealism.missingWindowRate(),
                requestedRealism.eventRate() == null ? 0.01 : requestedRealism.eventRate());
        BehaviorScenarioDefinition scenario = new BehaviorScenarioDefinition(
                request.scenarioId(),
                request.seed(),
                request.generatorVersion(),
                request.startAt(),
                request.endAt(),
                subjects,
                BehaviorTransitionMatrix.defaultMatrix(),
                initialWeights,
                realism);
        if (scenario.expectedWindows() * subjects.size() > MAX_WINDOWS) {
            throw new IllegalArgumentException("Too many windows");
        }
        return scenario;
    }

    private BehaviorSubject subject(BehaviorDatasetGenerateRequest.SubjectRequest request) {
        return new BehaviorSubject(
                request.tenantId(),
                request.farmId(),
                request.livestockId(),
                request.deviceId(),
                request.baselineRollDegrees() == null ? 0 : request.baselineRollDegrees(),
                request.baselinePitchDegrees() == null ? 0 : request.baselinePitchDegrees(),
                request.capsuleMotilityBaseline() == null ? 3 : request.capsuleMotilityBaseline());
    }

    private BehaviorEpisodeJpaEntity episodeEntity(UUID datasetId, BehaviorGeneratedEpisode episode) {
        BehaviorEpisodeJpaEntity entity = new BehaviorEpisodeJpaEntity();
        entity.setId(episode.id());
        entity.setDatasetId(datasetId);
        entity.setTenantId(episode.subject().tenantId());
        entity.setFarmId(episode.subject().farmId());
        entity.setLivestockId(episode.subject().livestockId());
        entity.setDeviceId(episode.subject().deviceId());
        entity.setDominantBehavior(episode.dominantBehavior().name());
        entity.setStartAt(episode.startAt());
        entity.setEndAt(episode.endAt());
        entity.setCreatedAt(Instant.now());
        return entity;
    }

    private BehaviorWindowJpaEntity windowEntity(
            UUID datasetId,
            BehaviorGeneratedWindow generated) {
        BehaviorWindowJpaEntity entity = new BehaviorWindowJpaEntity();
        entity.setId(deterministicId(datasetId + ":window:" + generated.subject().deviceId()
                + ":" + generated.startAt()));
        entity.setDatasetId(datasetId);
        entity.setEpisodeId(generated.episodeId());
        entity.setTenantId(generated.subject().tenantId());
        entity.setFarmId(generated.subject().farmId());
        entity.setLivestockId(generated.subject().livestockId());
        entity.setDeviceId(generated.subject().deviceId());
        entity.setWindowStart(generated.startAt());
        entity.setWindowEnd(generated.endAt());
        entity.setDominantBehavior(generated.dominantBehavior().name());
        entity.setFeatureVersion(
                com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract.VERSION_V1);
        entity.setFeatureSchemaHash(currentSchemaHash());
        entity.setFeatures(new LinkedHashMap<>(generated.feature().values()));
        entity.setInputQuality(generated.inputQuality().name());
        entity.setSamplingMode(generated.samplingMode().name());
        entity.setModelCompatible(generated.inputQuality() != InputQuality.UNKNOWN
                && generated.samplingMode() == SamplingMode.PROTOCOL_SUMMARY);
        entity.setCreatedAt(Instant.now());
        return entity;
    }

    private BehaviorWindowLabelJpaEntity labelEntity(
            UUID windowId,
            com.smartlivestock.datagen.domain.model.behavior.BehaviorFacet facet,
            com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue value) {
        BehaviorWindowLabelJpaEntity entity = new BehaviorWindowLabelJpaEntity();
        entity.setWindowId(windowId);
        entity.setFacet(facet.name());
        entity.setLabelValue(value.name());
        entity.setLabelSource(BehaviorLabelSource.SYNTHETIC.name());
        entity.setConfidence(BigDecimal.ONE);
        entity.setCreatedAt(Instant.now());
        return entity;
    }

    private BehaviorLivestockSplitAssignmentJpaEntity livestockSplitEntity(
            UUID datasetId,
            Long livestockId,
            BehaviorDatasetSplit split,
            DatagenOperatorContext operator) {
        BehaviorLivestockSplitAssignmentJpaEntity entity =
                new BehaviorLivestockSplitAssignmentJpaEntity();
        entity.setId(new BehaviorLivestockSplitId(datasetId, livestockId));
        entity.setDatasetSplit(split.name());
        entity.setAssignedBy(operator.userId());
        entity.setAssignedAt(Instant.now());
        return entity;
    }

    private BehaviorEpisodeSplitAssignmentJpaEntity episodeSplitEntity(
            UUID datasetId,
            UUID episodeId,
            BehaviorDatasetSplit split,
            DatagenOperatorContext operator) {
        BehaviorEpisodeSplitAssignmentJpaEntity entity =
                new BehaviorEpisodeSplitAssignmentJpaEntity();
        entity.setId(new BehaviorEpisodeSplitId(datasetId, episodeId));
        entity.setDatasetSplit(split.name());
        entity.setAssignedBy(operator.userId());
        entity.setAssignedAt(Instant.now());
        return entity;
    }

    private BehaviorDatasetSplit splitFor(Long livestockId) {
        int bucket = Math.floorMod(Long.hashCode(livestockId), 100);
        if (bucket < 70) return BehaviorDatasetSplit.TRAIN;
        if (bucket < 85) return BehaviorDatasetSplit.VALIDATION;
        return BehaviorDatasetSplit.TEST;
    }

    private Map<String, Object> manifestMap(BehaviorGenerationManifest manifest) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("dataset_id", manifest.datasetId());
        map.put("scenario_id", manifest.scenarioId());
        map.put("seed", manifest.seed());
        map.put("generator_version", manifest.generatorVersion());
        map.put("start_at", manifest.startAt());
        map.put("end_at", manifest.endAt());
        map.put("subject_count", manifest.subjectCount());
        map.put("expected_window_count", manifest.expectedWindowCount());
        map.put("generated_window_count", manifest.generatedWindowCount());
        map.put("episode_count", manifest.episodeCount());
        map.put("feature_version", manifest.featureVersion());
        map.put("feature_schema_hash", manifest.featureSchemaHash());
        return map;
    }

    private List<BehaviorWindowLabelJpaEntity> labelsFor(
            List<BehaviorWindowJpaEntity> windows) {
        if (windows.isEmpty()) return List.of();
        return labelRepository.findByWindowIdIn(windows.stream()
                .map(BehaviorWindowJpaEntity::getId)
                .toList());
    }

    private UUID deterministicId(String value) {
        return UUID.nameUUIDFromBytes(value.getBytes(StandardCharsets.UTF_8));
    }

    private String currentSchemaHash() {
        return com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract.v1()
                .schemaHash();
    }
}
