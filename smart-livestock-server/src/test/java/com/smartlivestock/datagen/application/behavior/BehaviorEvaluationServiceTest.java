package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEvaluationReport;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorEvaluationRequest;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorDatasetJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorEpisodeSplitAssignmentJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorPredictionJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.BehaviorWindowLabelJpaRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorDatasetJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeSplitAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeSplitId;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorPredictionJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowLabelJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BehaviorEvaluationServiceTest {
    private static final UUID DATASET_ID =
            UUID.fromString("00000000-0000-0000-0000-000000000101");
    private static final UUID EPISODE_ID =
            UUID.fromString("00000000-0000-0000-0000-000000000201");

    @Mock private DatagenFarmAccessService farmAccessService;
    @Mock private BehaviorDatasetJpaRepository datasetRepository;
    @Mock private BehaviorEpisodeJpaRepository episodeRepository;
    @Mock private BehaviorEpisodeSplitAssignmentJpaRepository episodeSplitRepository;
    @Mock private BehaviorWindowJpaRepository windowRepository;
    @Mock private BehaviorWindowLabelJpaRepository labelRepository;
    @Mock private BehaviorPredictionJpaRepository predictionRepository;

    private BehaviorEvaluationService service;

    @BeforeEach
    void setUp() {
        service = new BehaviorEvaluationService(
                farmAccessService,
                datasetRepository,
                episodeRepository,
                episodeSplitRepository,
                windowRepository,
                labelRepository,
                predictionRepository);
    }

    @Test
    void completeReportContainsDominantFacetBoundaryAndEventMetrics() {
        stubCompleteDataset();

        BehaviorEvaluationReport report = service.evaluate(
                new BehaviorEvaluationRequest(List.of(DATASET_ID), "TEST", false),
                platformOperator());

        assertEquals("COMPLETE", report.state());
        assertEquals("PIPELINE_ONLY", report.reportType());
        assertFalse(report.debug());
        assertEquals(0, report.missingPredictionWindows());
        assertEquals(List.of("DATAGEN"), report.dataSources());
        assertEquals(4, report.dominantMetrics().evaluatedWindows());
        assertEquals(0.75, report.dominantMetrics().accuracy());
        assertEquals(1.0, report.dominantMetrics().top2Accuracy());
        assertTrue(report.dominantMetrics().macroF1() > 0);
        assertTrue(report.dominantMetrics().weightedF1() > 0);
        assertEquals(1L, report.dominantMetrics().nearClassConfusion()
                .get("RUMINATING_AS_FEEDING"));
        assertEquals(1L, report.dominantMetrics().confusionMatrix()
                .get("RUMINATING").get("FEEDING"));
        assertEquals(4, report.facetMetrics().size());

        var oral = report.facetMetrics().stream()
                .filter(metric -> metric.facet().equals("ORAL_ACTIVITY"))
                .findFirst().orElseThrow();
        var rumination = oral.labels().stream()
                .filter(metric -> metric.label().equals("RUMINATING"))
                .findFirst().orElseThrow();
        assertEquals(1L, rumination.truePositive());
        assertEquals(1L, rumination.falseNegative());
        assertTrue(oral.hammingLoss() > 0);

        assertEquals(2L, report.boundaryMetrics().groundTruthTransitions());
        assertEquals(3L, report.boundaryMetrics().predictedTransitions());
        assertEquals(2L, report.boundaryMetrics().matchedTransitions());
        assertEquals(1L, report.eventMetrics().groundTruthEvents());
        assertEquals(1L, report.eventMetrics().matchedEvents());
        assertEquals(0L, report.eventMetrics().missedEvents());
        assertEquals(Map.of("DATAGEN", 4L), report.sourceCounts());
    }

    @Test
    void predictionFreeDatasetReturnsExplicitNoPredictionsState() {
        stubDataset(dataset(DATASET_ID, "DATAGEN"));
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(DATASET_ID))
                .thenReturn(List.of(episode()));
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        when(episodeSplitRepository.findByIdDatasetId(DATASET_ID))
                .thenReturn(List.of(episodeSplit()));
        List<BehaviorWindowJpaEntity> windows = windows();
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(DATASET_ID))
                .thenReturn(windows);
        when(labelRepository.findByWindowIdIn(anyCollection())).thenReturn(labels(windows));
        when(predictionRepository.findByWindowIdIn(anyCollection())).thenReturn(List.of());

        BehaviorEvaluationReport report = service.evaluate(
                new BehaviorEvaluationRequest(List.of(DATASET_ID), "TEST", false),
                platformOperator());

        assertEquals("NO_PREDICTIONS", report.state());
        assertEquals("PIPELINE_ONLY", report.reportType());
        assertEquals(4, report.missingPredictionWindows());
        assertEquals(0, report.dominantMetrics().evaluatedWindows());
        assertEquals(4, report.facetMetrics().size());
        assertEquals(5, report.dominantMetrics().classMetrics().size());
    }

    @Test
    void partialPredictionsAreExplicitlyReported() {
        stubDataset(dataset(DATASET_ID, "DATAGEN"));
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(DATASET_ID))
                .thenReturn(List.of(episode()));
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        when(episodeSplitRepository.findByIdDatasetId(DATASET_ID))
                .thenReturn(List.of(episodeSplit()));
        List<BehaviorWindowJpaEntity> windows = windows();
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(DATASET_ID))
                .thenReturn(windows);
        when(labelRepository.findByWindowIdIn(anyCollection())).thenReturn(labels(windows));
        List<BehaviorPredictionJpaEntity> predictions = predictions(windows);
        predictions.remove(0);
        when(predictionRepository.findByWindowIdIn(anyCollection())).thenReturn(predictions);

        BehaviorEvaluationReport report = service.evaluate(
                new BehaviorEvaluationRequest(List.of(DATASET_ID), "TEST", false),
                platformOperator());

        assertEquals("PARTIAL_PREDICTIONS", report.state());
        assertEquals(1, report.missingPredictionWindows());
        assertEquals(3, report.dominantMetrics().evaluatedWindows());
        assertTrue(report.sourceCounts().containsKey("DATAGEN"));
    }

    @Test
    void mixedSourcesRequireExplicitDebugMode() {
        UUID realDatasetId = UUID.fromString("00000000-0000-0000-0000-000000000102");
        stubDataset(dataset(DATASET_ID, "DATAGEN"));
        stubDataset(dataset(realDatasetId, "AGENTIC_PLATFORM"));
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(DATASET_ID)).thenReturn(List.of());
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(realDatasetId)).thenReturn(List.of());
        when(episodeSplitRepository.findByIdDatasetId(DATASET_ID)).thenReturn(List.of());
        when(episodeSplitRepository.findByIdDatasetId(realDatasetId)).thenReturn(List.of());
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(DATASET_ID)).thenReturn(List.of());
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(realDatasetId)).thenReturn(List.of());

        assertThrows(ApiException.class, () -> service.evaluate(
                new BehaviorEvaluationRequest(List.of(DATASET_ID, realDatasetId), "TEST", false),
                platformOperator()));

        BehaviorEvaluationReport report = service.evaluate(
                new BehaviorEvaluationRequest(List.of(DATASET_ID, realDatasetId), "TEST", true),
                platformOperator());

        assertTrue(report.debug());
        assertEquals("NO_WINDOWS", report.state());
        assertEquals("PIPELINE_ONLY", report.reportType());
    }

    @Test
    void rejectsEmptyDatasetSelection() {
        ApiException exception = assertThrows(ApiException.class, () -> service.evaluate(
                new BehaviorEvaluationRequest(List.of(), "TEST", false), platformOperator()));
        assertEquals("VALIDATION_ERROR", exception.getCode().name());
    }

    private void stubCompleteDataset() {
        stubDataset(dataset(DATASET_ID, "DATAGEN"));
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(DATASET_ID))
                .thenReturn(List.of(episode()));
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        when(episodeSplitRepository.findByIdDatasetId(DATASET_ID))
                .thenReturn(List.of(episodeSplit()));
        List<BehaviorWindowJpaEntity> windows = windows();
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(DATASET_ID))
                .thenReturn(windows);
        when(labelRepository.findByWindowIdIn(anyCollection())).thenReturn(labels(windows));
        when(predictionRepository.findByWindowIdIn(anyCollection())).thenReturn(predictions(windows));
    }

    private void stubDataset(BehaviorDatasetJpaEntity dataset) {
        when(datasetRepository.findById(dataset.getId())).thenReturn(Optional.of(dataset));
    }

    private BehaviorDatasetJpaEntity dataset(UUID id, String source) {
        var dataset = new BehaviorDatasetJpaEntity();
        dataset.setId(id);
        dataset.setScenarioId("evaluation");
        dataset.setSeed(1L);
        dataset.setGeneratorVersion("behavior-generator-v1");
        dataset.setDataSource(source);
        dataset.setStatus("READY");
        dataset.setStartAt(Instant.parse("2026-08-23T00:00:00Z"));
        dataset.setEndAt(Instant.parse("2026-08-23T00:20:00Z"));
        return dataset;
    }

    private BehaviorEpisodeJpaEntity episode() {
        var episode = new BehaviorEpisodeJpaEntity();
        episode.setId(EPISODE_ID);
        episode.setDatasetId(DATASET_ID);
        episode.setTenantId(1L);
        episode.setFarmId(1L);
        episode.setLivestockId(1L);
        episode.setDeviceId(5L);
        episode.setDominantBehavior("OTHER");
        episode.setStartAt(Instant.parse("2026-08-23T00:00:00Z"));
        episode.setEndAt(Instant.parse("2026-08-23T00:20:00Z"));
        return episode;
    }

    private BehaviorEpisodeSplitAssignmentJpaEntity episodeSplit() {
        var split = new BehaviorEpisodeSplitAssignmentJpaEntity();
        split.setId(new BehaviorEpisodeSplitId(DATASET_ID, EPISODE_ID));
        split.setDatasetSplit("TEST");
        return split;
    }

    private List<BehaviorWindowJpaEntity> windows() {
        String[] dominants = {"LYING", "RUMINATING", "RUMINATING", "WALKING"};
        List<BehaviorWindowJpaEntity> windows = new ArrayList<>();
        for (int i = 0; i < dominants.length; i++) {
            var window = new BehaviorWindowJpaEntity();
            window.setId(UUID.fromString("00000000-0000-0000-0000-0000000003%02d".formatted(i + 1)));
            window.setDatasetId(DATASET_ID);
            window.setEpisodeId(EPISODE_ID);
            window.setTenantId(1L);
            window.setFarmId(1L);
            window.setLivestockId(1L);
            window.setDeviceId(5L);
            window.setWindowStart(Instant.parse("2026-08-23T00:00:00Z").plusSeconds(i * 300L));
            window.setWindowEnd(window.getWindowStart().plusSeconds(300));
            window.setDominantBehavior(dominants[i]);
            window.setFeatureVersion("v1");
            window.setFeatureSchemaHash("hash");
            window.setFeatures(Map.of("sample_count", 7500));
            window.setInputQuality("FULL_0X40");
            window.setSamplingMode("PROTOCOL_SUMMARY");
            window.setModelCompatible(true);
            windows.add(window);
        }
        return windows;
    }

    private List<BehaviorWindowLabelJpaEntity> labels(List<BehaviorWindowJpaEntity> windows) {
        List<BehaviorWindowLabelJpaEntity> labels = new ArrayList<>();
        String[] oral = {"NONE", "RUMINATING", "RUMINATING", "NONE"};
        String[] posture = {"LYING", "LYING", "STANDING", "STANDING"};
        String[] locomotion = {"STATIONARY", "STATIONARY", "STATIONARY", "WALKING"};
        for (int i = 0; i < windows.size(); i++) {
            labels.add(label(windows.get(i).getId(), "POSTURE", posture[i]));
            labels.add(label(windows.get(i).getId(), "ORAL_ACTIVITY", oral[i]));
            labels.add(label(windows.get(i).getId(), "LOCOMOTION", locomotion[i]));
            labels.add(label(windows.get(i).getId(), "EVENT",
                    i == 1 ? "CALVING_RISK" : "NONE"));
        }
        return labels;
    }

    private BehaviorWindowLabelJpaEntity label(UUID windowId, String facet, String value) {
        var label = new BehaviorWindowLabelJpaEntity();
        label.setWindowId(windowId);
        label.setFacet(facet);
        label.setLabelValue(value);
        label.setLabelSource("SYNTHETIC");
        label.setConfidence(BigDecimal.ONE);
        return label;
    }

    private List<BehaviorPredictionJpaEntity> predictions(List<BehaviorWindowJpaEntity> windows) {
        String[] predicted = {"LYING", "RUMINATING", "FEEDING", "WALKING"};
        List<BehaviorPredictionJpaEntity> predictions = new ArrayList<>();
        for (int i = 0; i < windows.size(); i++) {
            String actual = windows.get(i).getDominantBehavior();
            String predictionValue = predicted[i];
            var prediction = new BehaviorPredictionJpaEntity();
            prediction.setId(UUID.fromString("00000000-0000-0000-0000-0000000004%02d".formatted(i + 1)));
            prediction.setWindowId(windows.get(i).getId());
            prediction.setModelName("fixture-model");
            prediction.setModelVersion("1");
            prediction.setPredictedDominantBehavior(predictionValue);
            prediction.setDominantProbability(BigDecimal.valueOf(0.8));
            prediction.setPredictedLabels(Map.of(
                    "POSTURE", i == 2 ? "STANDING" : windows.get(i).getDominantBehavior(),
                    "ORAL_ACTIVITY", i == 0 || i == 3 ? "NONE" : predicted[i],
                    "LOCOMOTION", i == 3 ? "WALKING" : "STATIONARY",
                    "EVENT", i == 1 ? "CALVING_RISK" : "NONE"));
            Map<String, Object> probabilities = new LinkedHashMap<>();
            probabilities.put(actual, 0.5);
            if (!actual.equals(predictionValue)) {
                probabilities.put(predictionValue, 0.4);
            }
            probabilities.put("OTHER", 0.1);
            prediction.setProbabilityVector(probabilities);
            prediction.setCapabilityLevel("L2_SUPERVISED");
            prediction.setPredictedAt(Instant.parse("2026-08-23T01:00:00Z"));
            predictions.add(prediction);
        }
        return predictions;
    }

    private DatagenOperatorContext platformOperator() {
        return new DatagenOperatorContext(
                1L, 1L, DatagenOperatorContext.DatagenOperatorRole.PLATFORM_ADMIN);
    }
}
