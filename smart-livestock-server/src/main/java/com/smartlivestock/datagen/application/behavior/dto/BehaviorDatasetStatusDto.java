package com.smartlivestock.datagen.application.behavior.dto;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record BehaviorDatasetStatusDto(
        UUID id,
        String scenarioId,
        long seed,
        String generatorVersion,
        String dataSource,
        String status,
        Instant startAt,
        Instant endAt,
        int episodeCount,
        int windowCount,
        int labelCount,
        Map<String, Long> splitCounts,
        Map<String, Long> dominantCounts,
        Map<String, Long> qualityCounts,
        boolean alreadyExists) {
}
