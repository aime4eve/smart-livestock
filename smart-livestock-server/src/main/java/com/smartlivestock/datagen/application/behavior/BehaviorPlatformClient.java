package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformAnalysis;
import com.smartlivestock.datagen.application.behavior.dto.BehaviorPlatformTraining;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;

import java.util.List;
import java.util.Map;

public interface BehaviorPlatformClient {
    BehaviorPlatformTraining train(String datasetId, String modelName, String modelVersion,
                                   int minimumSupport, Integer randomSeed);

    BehaviorPlatformAnalysis analyze(Long tenantId, Long farmId, String capability,
                                     String modelName, String modelVersion,
                                     List<BehaviorWindowJpaEntity> windows);

    static Map<String, Object> windowBody(BehaviorWindowJpaEntity window) {
        return Map.of(
                "window_id", window.getId().toString(),
                "feature_version", window.getFeatureVersion(),
                "feature_schema_hash", window.getFeatureSchemaHash(),
                "input_quality", window.getInputQuality(),
                "sampling_mode", window.getSamplingMode(),
                "features", window.getFeatures());
    }
}
