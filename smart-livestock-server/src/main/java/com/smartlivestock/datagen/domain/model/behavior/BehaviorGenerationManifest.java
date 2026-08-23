package com.smartlivestock.datagen.domain.model.behavior;

import java.time.Instant;
import java.util.UUID;

public record BehaviorGenerationManifest(
        UUID datasetId,
        String scenarioId,
        long seed,
        String generatorVersion,
        Instant startAt,
        Instant endAt,
        int subjectCount,
        int expectedWindowCount,
        int generatedWindowCount,
        int episodeCount,
        String featureVersion,
        String featureSchemaHash) {
}
