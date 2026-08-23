package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetExport;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorTransitionMatrix;
import com.smartlivestock.datagen.domain.service.BehaviorDatasetGenerator;
import com.smartlivestock.datagen.domain.service.BehaviorFeatureValidator;
import com.smartlivestock.datagen.domain.service.BehaviorWaveformGenerator;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BehaviorDatasetExportServiceTest {
    @Test
    void exportsCanonicalDatasetAndScenarioDigest() {
        BehaviorDatasetCanonicalizer canonicalizer = new BehaviorDatasetCanonicalizer();
        BehaviorDatasetExportService service = new BehaviorDatasetExportService(canonicalizer);
        BehaviorScenarioDefinition scenario = scenario(1);
        BehaviorGeneratedDataset dataset = generator().generate(scenario);

        BehaviorDatasetExport export = service.export(scenario, dataset);

        assertEquals("datagen-behavior-v1", export.formatVersion());
        assertEquals(canonicalizer.scenarioDigest(scenario), export.scenarioDigest());
        assertEquals(canonicalizer.semanticDigest(dataset), export.datasetDigest());
        assertEquals(canonicalizer.canonicalDataset(dataset), export.content());
    }

    @Test
    void rejectsDatasetFromAnotherScenario() {
        BehaviorDatasetExportService service =
                new BehaviorDatasetExportService(new BehaviorDatasetCanonicalizer());
        BehaviorGeneratedDataset dataset = generator().generate(scenario(1));

        assertThrows(IllegalArgumentException.class, () -> service.export(scenario(2), dataset));
    }

    private BehaviorDatasetGenerator generator() {
        return new BehaviorDatasetGenerator(
                new BehaviorWaveformGenerator(new BehaviorFeatureValidator()));
    }

    private BehaviorScenarioDefinition scenario(long seed) {
        return new BehaviorScenarioDefinition(
                "export-smoke",
                seed,
                "behavior-generator-v1",
                Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-23T00:05:00Z"),
                List.of(new BehaviorSubject(1L, 1L, 1L, 5L, 8, -4, 3.2)),
                BehaviorTransitionMatrix.defaultMatrix(),
                List.of(1.0, 1.0, 1.0, 1.0, 1.0),
                new BehaviorRealismProfile(0.001, 0, 0, 0));
    }
}
