package com.smartlivestock.datagen.application.behavior.dto;

import java.util.Map;

public record BehaviorPlatformPrediction(
        String windowId,
        String dominantBehavior,
        Map<String, Double> probabilityVector,
        Map<String, String> predictedLabels,
        String capabilityLevel,
        String modelName,
        String modelVersion) {
}
