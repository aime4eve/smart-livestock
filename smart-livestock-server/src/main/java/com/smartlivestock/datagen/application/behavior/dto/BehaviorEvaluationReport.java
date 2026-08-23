package com.smartlivestock.datagen.application.behavior.dto;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record BehaviorEvaluationReport(
        String state,
        String reportType,
        boolean debug,
        List<UUID> datasetIds,
        List<String> dataSources,
        List<String> generatorVersions,
        List<String> modelVersions,
        Map<String, Long> sourceCounts,
        Map<String, Long> inputQualityCounts,
        Map<String, Long> splitCounts,
        Map<String, Long> livestockCounts,
        BehaviorDominantMetrics dominantMetrics,
        List<BehaviorFacetMetrics> facetMetrics,
        BehaviorBoundaryMetrics boundaryMetrics,
        BehaviorEventMetrics eventMetrics) {
}
