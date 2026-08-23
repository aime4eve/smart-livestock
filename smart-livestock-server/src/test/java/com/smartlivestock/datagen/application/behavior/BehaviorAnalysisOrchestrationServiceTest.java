package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorAnalyzeRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorModelTrainRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformAnalysis;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformPrediction;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformTraining;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.ArgumentCaptor;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class BehaviorAnalysisOrchestrationServiceTest {
    private static final UUID DATASET_ID = UUID.fromString(
            "00000000-0000-0000-0000-000000000101");
    private static final UUID WINDOW_ID = UUID.fromString(
            "00000000-0000-0000-0000-000000000301");

    @Mock private BehaviorPlatformClient platformClient;
    @Mock private DatagenFarmAccessService farmAccessService;
    @Mock private BehaviorDatasetJpaRepository datasetRepository;
    @Mock private BehaviorEpisodeJpaRepository episodeRepository;
    @Mock private BehaviorWindowJpaRepository windowRepository;
    @Mock private BehaviorPredictionJpaRepository predictionRepository;

    private BehaviorAnalysisOrchestrationService service;

    @BeforeEach
    void setUp() {
        service = new BehaviorAnalysisOrchestrationService(
                platformClient,
                new BehaviorFeatureValidator(),
                farmAccessService,
                datasetRepository,
                episodeRepository,
                windowRepository,
                predictionRepository);
    }

    @Test
    void analyzeL1PersistsValidatedPrediction() {
        stubDataset("DATAGEN");
        stubWindows();
        when(platformClient.analyze(any(), any(), eq("L1_RULE"), any(), any(), anyList()))
                .thenReturn(new BehaviorPlatformAnalysis(List.of(prediction()), List.of()));
        when(predictionRepository.findByWindowIdInAndModelNameAndModelVersion(
                anyList(), eq("behavior-rules"), eq("v1"))).thenReturn(List.of());
        BehaviorPredictionJpaEntity saved = new BehaviorPredictionJpaEntity();
        when(predictionRepository.save(any())).thenAnswer(invocation -> {
            BehaviorPredictionJpaEntity entity = invocation.getArgument(0);
            saved.setId(entity.getId());
            saved.setWindowId(entity.getWindowId());
            saved.setModelName(entity.getModelName());
            return entity;
        });

        var result = service.analyze(
                DATASET_ID, new BehaviorAnalyzeRequest("L1_RULE", null, null),
                platformOperator());

        assertEquals(1, result.predictionCount());
        assertEquals("L1_RULE", result.capabilityLevel());
        assertEquals(WINDOW_ID, saved.getWindowId());
        assertEquals("behavior-rules", saved.getModelName());
    }

    @Test
    void repeatedAnalysisUpdatesExistingModelRow() {
        BehaviorPredictionJpaEntity existing = new BehaviorPredictionJpaEntity();
        existing.setId(UUID.fromString("00000000-0000-0000-0000-000000000401"));
        existing.setWindowId(WINDOW_ID);
        existing.setModelName("behavior-rules");
        existing.setModelVersion("v1");
        stubDataset("DATAGEN");
        stubWindows();
        when(platformClient.analyze(any(), any(), eq("L1_RULE"), any(), any(), anyList()))
                .thenReturn(new BehaviorPlatformAnalysis(List.of(prediction()), List.of()));
        when(predictionRepository.findByWindowIdInAndModelNameAndModelVersion(
                anyList(), eq("behavior-rules"), eq("v1"))).thenReturn(List.of(existing));
        when(predictionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.analyze(DATASET_ID,
                new BehaviorAnalyzeRequest("L1_RULE", null, null), platformOperator());

        ArgumentCaptor<BehaviorPredictionJpaEntity> captor =
                ArgumentCaptor.forClass(BehaviorPredictionJpaEntity.class);
        verify(predictionRepository).save(captor.capture());
        assertSame(existing, captor.getValue());
    }

    @Test
    void analyzeRejectsL2WithoutModelIdentity() {
        stubDataset("DATAGEN");
        stubWindows();

        ApiException exception = assertThrows(ApiException.class, () -> service.analyze(
                DATASET_ID,
                new BehaviorAnalyzeRequest("L2_SUPERVISED", null, null),
                platformOperator()));

        assertEquals("VALIDATION_ERROR", exception.getCode().name());
    }

    @Test
    void trainRequiresSyntheticDatasetAndL2Request() {
        stubDataset("AGENTIC_PLATFORM");

        ApiException exception = assertThrows(ApiException.class, () -> service.train(
                DATASET_ID,
                new BehaviorModelTrainRequest("L2_SUPERVISED", "m", "v1", 1, 149),
                platformOperator()));

        assertEquals("STATE_CONFLICT", exception.getCode().name());
    }

    @Test
    void trainDelegatesValidSyntheticDataset() {
        stubDataset("DATAGEN");
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(DATASET_ID))
                .thenReturn(List.of(episode()));
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        BehaviorPlatformTraining training = new BehaviorPlatformTraining(
                DATASET_ID.toString(), "behavior-l2", "v1", "hash", Map.of());
        when(platformClient.train(DATASET_ID.toString(), "behavior-l2", "v1", 1, 149))
                .thenReturn(training);

        BehaviorPlatformTraining result = service.train(
                DATASET_ID,
                new BehaviorModelTrainRequest("L2_SUPERVISED", "behavior-l2", "v1", 1, 149),
                platformOperator());

        assertEquals(training, result);
    }

    private void stubDataset(String source) {
        BehaviorDatasetJpaEntity dataset = new BehaviorDatasetJpaEntity();
        dataset.setId(DATASET_ID);
        dataset.setDataSource(source);
        when(datasetRepository.findById(DATASET_ID)).thenReturn(Optional.of(dataset));
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(DATASET_ID))
                .thenReturn(List.of(episode()));
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
    }

    private void stubWindows() {
        BehaviorWindowJpaEntity window = window();
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(DATASET_ID))
                .thenReturn(List.of(window));
    }

    private BehaviorEpisodeJpaEntity episode() {
        BehaviorEpisodeJpaEntity episode = new BehaviorEpisodeJpaEntity();
        episode.setId(UUID.fromString("00000000-0000-0000-0000-000000000201"));
        episode.setDatasetId(DATASET_ID);
        episode.setFarmId(1L);
        return episode;
    }

    private BehaviorWindowJpaEntity window() {
        BehaviorWindowJpaEntity window = new BehaviorWindowJpaEntity();
        window.setId(WINDOW_ID);
        window.setDatasetId(DATASET_ID);
        window.setTenantId(1L);
        window.setFarmId(1L);
        window.setFeatureVersion(BehaviorFeatureContract.VERSION_V1);
        window.setFeatureSchemaHash(BehaviorFeatureContract.v1().schemaHash());
        window.setInputQuality("FULL_0X40");
        window.setSamplingMode("PROTOCOL_SUMMARY");
        window.setModelCompatible(true);
        Map<String, Object> features = BehaviorFeatureContract.v1().fields().stream()
                .collect(Collectors.toMap(
                        field -> field.name(),
                        field -> field.name().equals("sample_count") ? 7500
                                : field.name().equals("expected_sample_count") ? 7500 : 0,
                        (first, second) -> first,
                        LinkedHashMap::new));
        window.setFeatures(features);
        return window;
    }

    private BehaviorPlatformPrediction prediction() {
        return new BehaviorPlatformPrediction(
                WINDOW_ID.toString(),
                "OTHER",
                Map.of("OTHER", 0.8, "LYING", 0.1, "WALKING", 0.1),
                Map.of("POSTURE", "STANDING", "LOCOMOTION", "STATIONARY"),
                "L1_RULE",
                "behavior-rules",
                "v1");
    }

    private DatagenOperatorContext platformOperator() {
        return new DatagenOperatorContext(
                1L, 1L, DatagenOperatorContext.DatagenOperatorRole.PLATFORM_ADMIN);
    }
}
