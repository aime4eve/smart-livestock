package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.DatagenFarmAccessService;
import com.smartlivestock.datagen.application.DatagenOperatorContext;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetGenerateRequest;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetStatusDto;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.port.BehaviorSubjectScopePort;
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
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowLabelJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BehaviorDatasetPersistenceServiceTest {
    @Mock private DatagenFarmAccessService farmAccessService;
    @Mock private BehaviorSubjectScopePort subjectScopePort;
    @Mock private BehaviorFeatureContractJpaRepository contractRepository;
    @Mock private BehaviorDatasetJpaRepository datasetRepository;
    @Mock private BehaviorEpisodeJpaRepository episodeRepository;
    @Mock private BehaviorLivestockSplitAssignmentJpaRepository livestockSplitRepository;
    @Mock private BehaviorEpisodeSplitAssignmentJpaRepository episodeSplitRepository;
    @Mock private BehaviorWindowJpaRepository windowRepository;
    @Mock private BehaviorWindowLabelJpaRepository labelRepository;

    private final BehaviorFeatureValidator featureValidator = new BehaviorFeatureValidator();
    private final BehaviorGenerationService generationService =
            new BehaviorGenerationService(featureValidator);
    private final BehaviorDatasetCanonicalizer canonicalizer =
            new BehaviorDatasetCanonicalizer();
    private BehaviorDatasetPersistenceService service;

    @BeforeEach
    void setUp() {
        service = new BehaviorDatasetPersistenceService(
                generationService,
                canonicalizer,
                featureValidator,
                farmAccessService,
                subjectScopePort,
                contractRepository,
                datasetRepository,
                episodeRepository,
                livestockSplitRepository,
                episodeSplitRepository,
                windowRepository,
                labelRepository);
    }

    @Test
    void generatesAndPersistsSyntheticDatasetWithGovernedSplits() {
        BehaviorDatasetGenerateRequest request = request(Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-23T00:05:00Z"));
        BehaviorGeneratedDataset expected = generationService.generate(
                scenarioFromRequest(request));
        UUID datasetId = expected.manifest().datasetId();

        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        when(contractRepository.findById(BehaviorFeatureContract.VERSION_V1))
                .thenReturn(Optional.of(contractEntity()));
        when(datasetRepository.findByDefinitionDigest(any())).thenReturn(Optional.empty());

        BehaviorDatasetJpaEntity datasetEntity = new BehaviorDatasetJpaEntity();
        datasetEntity.setId(datasetId);
        datasetEntity.setScenarioId("behavior-persistence");
        datasetEntity.setSeed(1001);
        datasetEntity.setGeneratorVersion("behavior-generator-v1");
        datasetEntity.setDataSource("DATAGEN");
        datasetEntity.setStatus("READY");
        datasetEntity.setStartAt(expected.manifest().startAt());
        datasetEntity.setEndAt(expected.manifest().endAt());
        when(datasetRepository.saveAndFlush(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(datasetRepository.findById(datasetId)).thenReturn(Optional.of(datasetEntity));

        List<BehaviorEpisodeJpaEntity> episodes = new ArrayList<>();
        when(episodeRepository.saveAll(any())).thenAnswer(invocation -> {
            episodes.addAll((List<BehaviorEpisodeJpaEntity>) invocation.getArgument(0));
            return episodes;
        });
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(datasetId)).thenReturn(episodes);
        when(livestockSplitRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        List<BehaviorEpisodeSplitAssignmentJpaEntity> episodeSplits = new ArrayList<>();
        when(episodeSplitRepository.saveAll(any())).thenAnswer(invocation -> {
            episodeSplits.addAll((List<BehaviorEpisodeSplitAssignmentJpaEntity>) invocation.getArgument(0));
            return episodeSplits;
        });
        when(episodeSplitRepository.findByIdDatasetId(datasetId)).thenReturn(episodeSplits);

        List<BehaviorWindowJpaEntity> windows = new ArrayList<>();
        when(windowRepository.saveAll(any())).thenAnswer(invocation -> {
            windows.addAll((List<BehaviorWindowJpaEntity>) invocation.getArgument(0));
            return windows;
        });
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(datasetId)).thenReturn(windows);

        List<BehaviorWindowLabelJpaEntity> labels = new ArrayList<>();
        when(labelRepository.saveAll(any())).thenAnswer(invocation -> {
            labels.addAll((List<BehaviorWindowLabelJpaEntity>) invocation.getArgument(0));
            return labels;
        });
        when(labelRepository.findByWindowIdIn(anyCollection())).thenReturn(labels);

        BehaviorDatasetStatusDto status = service.generate(request, platformOperator());

        assertEquals(datasetId, status.id());
        assertEquals("DATAGEN", status.dataSource());
        assertEquals(1, status.episodeCount());
        assertEquals(1, status.windowCount());
        assertEquals(4, status.labelCount());
        assertEquals(1, status.dominantCounts().size());
        assertEquals(1, status.splitCounts().size());
        assertTrue(status.splitCounts().containsKey("TRAIN")
                || status.splitCounts().containsKey("VALIDATION")
                || status.splitCounts().containsKey("TEST"));
        verify(windowRepository).saveAll(windows);
        verify(labelRepository).saveAll(labels);
        assertEquals(BehaviorFeatureContract.v1().schemaHash(),
                windows.get(0).getFeatureSchemaHash());
    }

    @Test
    void sameCanonicalDefinitionIsIdempotent() {
        BehaviorDatasetGenerateRequest request = request(Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-23T00:05:00Z"));
        BehaviorGeneratedDataset expected = generationService.generate(
                scenarioFromRequest(request));
        UUID datasetId = expected.manifest().datasetId();
        BehaviorDatasetJpaEntity existing = new BehaviorDatasetJpaEntity();
        existing.setId(datasetId);
        existing.setStartAt(expected.manifest().startAt());
        existing.setEndAt(expected.manifest().endAt());

        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        when(datasetRepository.findByDefinitionDigest(any()))
                .thenReturn(Optional.of(existing));
        when(datasetRepository.findById(datasetId)).thenReturn(Optional.of(existing));
        when(episodeRepository.findByDatasetIdOrderByStartAtAsc(datasetId)).thenReturn(List.of());
        when(episodeSplitRepository.findByIdDatasetId(datasetId)).thenReturn(List.of());
        when(windowRepository.findByDatasetIdOrderByWindowStartAsc(datasetId)).thenReturn(List.of());

        BehaviorDatasetStatusDto status = service.generate(request, platformOperator());

        assertTrue(status.alreadyExists());
        verify(datasetRepository).findByDefinitionDigest(
                canonicalizer.scenarioDigest(scenarioFromRequest(request)));
        verify(datasetRepository, never()).saveAndFlush(any());
    }

    @Test
    void rejectsTooManyWindows() {
        BehaviorDatasetGenerateRequest request = request(
                Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-09-23T00:00:00Z"), 50);
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);

        ApiException exception = assertThrows(ApiException.class,
                () -> service.generate(request, platformOperator()));

        assertEquals("VALIDATION_ERROR", exception.getCode().name());
        verify(datasetRepository, never()).saveAndFlush(any());
    }

    @Test
    void validatesSubjectScopeBeforeGeneratingDataset() {
        BehaviorDatasetGenerateRequest request = request(
                Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-23T00:05:00Z"));
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);
        doThrow(new IllegalArgumentException("invalid scope"))
                .when(subjectScopePort).validate(any(), any());

        ApiException exception = assertThrows(ApiException.class,
                () -> service.generate(request, platformOperator()));

        assertEquals("VALIDATION_ERROR", exception.getCode().name());
        verify(subjectScopePort).validate(any(), any());
        verify(datasetRepository, never()).findByDefinitionDigest(any());
        verify(datasetRepository, never()).saveAndFlush(any());
    }

    @Test
    void rejectsNullInitialWeightWithoutInternalServerError() {
        BehaviorDatasetGenerateRequest base = request(
                Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-23T00:05:00Z"));
        BehaviorDatasetGenerateRequest request = new BehaviorDatasetGenerateRequest(
                base.scenarioId(),
                base.seed(),
                base.generatorVersion(),
                base.startAt(),
                base.endAt(),
                base.subjects(),
                java.util.Arrays.asList(4.0, null, 2.0, 1.0, 0.2),
                base.realism());
        when(farmAccessService.requireAccessibleFarm(any(), any())).thenReturn(null);

        ApiException exception = assertThrows(ApiException.class,
                () -> service.generate(request, platformOperator()));

        assertEquals("VALIDATION_ERROR", exception.getCode().name());
    }

    private BehaviorDatasetGenerateRequest request(Instant start, Instant end) {
        return request(start, end, 1);
    }

    private BehaviorDatasetGenerateRequest request(Instant start, Instant end, int subjectCount) {
        List<BehaviorDatasetGenerateRequest.SubjectRequest> subjects = new ArrayList<>();
        for (int i = 0; i < subjectCount; i++) {
            subjects.add(new BehaviorDatasetGenerateRequest.SubjectRequest(
                    1L, 1L, (long) (i + 1), (long) (i + 5), 8.0, -4.0, 3.2));
        }
        return new BehaviorDatasetGenerateRequest(
                "behavior-persistence",
                1001L,
                "behavior-generator-v1",
                start,
                end,
                subjects,
                List.of(4.0, 3.0, 2.0, 1.0, 0.2),
                new BehaviorDatasetGenerateRequest.RealismRequest(0.001, 0.0, 0.0, 0.0));
    }

    private com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition scenarioFromRequest(
            BehaviorDatasetGenerateRequest request) {
        var subject = request.subjects().get(0);
        return new com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition(
                request.scenarioId(),
                request.seed(),
                request.generatorVersion(),
                request.startAt(),
                request.endAt(),
                List.of(new com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject(
                        subject.tenantId(),
                        subject.farmId(),
                        subject.livestockId(),
                        subject.deviceId(),
                        subject.baselineRollDegrees(),
                        subject.baselinePitchDegrees(),
                        subject.capsuleMotilityBaseline())),
                com.smartlivestock.datagen.domain.model.behavior.BehaviorTransitionMatrix.defaultMatrix(),
                request.initialWeights(),
                new com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile(
                        request.realism().noiseStdDevG(),
                        request.realism().sampleDropoutRate(),
                        request.realism().missingWindowRate(),
                        request.realism().eventRate()));
    }

    private com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorFeatureContractJpaEntity contractEntity() {
        var entity = new com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorFeatureContractJpaEntity();
        entity.setFeatureVersion(BehaviorFeatureContract.VERSION_V1);
        entity.setSchemaHash(BehaviorFeatureContract.v1().schemaHash());
        entity.setDefinition(Map.of("featureVersion", BehaviorFeatureContract.VERSION_V1));
        return entity;
    }

    private DatagenOperatorContext platformOperator() {
        return new DatagenOperatorContext(
                1L, 1L, DatagenOperatorContext.DatagenOperatorRole.PLATFORM_ADMIN);
    }
}
