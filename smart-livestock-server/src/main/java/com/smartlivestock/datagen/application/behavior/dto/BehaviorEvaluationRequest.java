package com.smartlivestock.datagen.application.behavior.dto;

import java.util.List;
import java.util.UUID;

public record BehaviorEvaluationRequest(
        List<UUID> datasetIds,
        String datasetSplit,
        boolean allowMixedDebug) {
}
