package com.smartlivestock.datagen.application.behavior.dto;

import java.util.Map;

public record BehaviorPlatformTraining(
        String datasetId,
        String modelName,
        String modelVersion,
        String artifactHash,
        Map<String, Object> manifest) {
}
