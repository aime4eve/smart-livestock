package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.service.BehaviorDatasetGenerator;
import com.smartlivestock.datagen.domain.service.BehaviorFeatureValidator;
import com.smartlivestock.datagen.domain.service.BehaviorWaveformGenerator;
import org.springframework.stereotype.Service;

@Service
public class BehaviorGenerationService {
    private final BehaviorDatasetGenerator generator;

    public BehaviorGenerationService(BehaviorFeatureValidator featureValidator) {
        this.generator = new BehaviorDatasetGenerator(
                new BehaviorWaveformGenerator(featureValidator));
    }

    public BehaviorGeneratedDataset generate(BehaviorScenarioDefinition scenario) {
        return generator.generate(scenario);
    }
}
