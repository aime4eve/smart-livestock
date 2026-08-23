package com.smartlivestock.datagen.application.behavior.dto;

import java.util.List;
import java.util.Map;

public record BehaviorPlatformAnalysis(
        List<BehaviorPlatformPrediction> results,
        List<Map<String, String>> errors) {
}
