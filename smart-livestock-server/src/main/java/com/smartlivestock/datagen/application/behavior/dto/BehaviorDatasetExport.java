package com.smartlivestock.datagen.application.behavior.dto;

public record BehaviorDatasetExport(
        String formatVersion,
        String scenarioDigest,
        String datasetDigest,
        String content) {
}
