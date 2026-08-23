package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.behavior.dto.BehaviorDatasetExport;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import org.springframework.stereotype.Service;

@Service
public class BehaviorDatasetExportService {
    private final BehaviorDatasetCanonicalizer canonicalizer;

    public BehaviorDatasetExportService(BehaviorDatasetCanonicalizer canonicalizer) {
        this.canonicalizer = canonicalizer;
    }

    public BehaviorDatasetExport export(
            BehaviorScenarioDefinition scenario,
            BehaviorGeneratedDataset dataset) {
        if (!scenario.scenarioId().equals(dataset.manifest().scenarioId())
                || scenario.seed() != dataset.manifest().seed()
                || !scenario.generatorVersion().equals(dataset.manifest().generatorVersion())
                || !scenario.startAt().equals(dataset.manifest().startAt())
                || !scenario.endAt().equals(dataset.manifest().endAt())
                || scenario.subjects().size() != dataset.manifest().subjectCount()) {
            throw new IllegalArgumentException("Dataset does not match its scenario");
        }
        return new BehaviorDatasetExport(
                "datagen-behavior-v1",
                canonicalizer.scenarioDigest(scenario),
                canonicalizer.semanticDigest(dataset),
                canonicalizer.canonicalDataset(dataset));
    }
}
