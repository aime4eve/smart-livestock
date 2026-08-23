package com.smartlivestock.datagen.application.behavior.dto;

import java.time.Instant;
import java.util.List;

public record BehaviorDatasetGenerateRequest(
        String scenarioId,
        Long seed,
        String generatorVersion,
        Instant startAt,
        Instant endAt,
        List<SubjectRequest> subjects,
        List<Double> initialWeights,
        RealismRequest realism) {

    public record SubjectRequest(
            Long tenantId,
            Long farmId,
            Long livestockId,
            Long deviceId,
            Double baselineRollDegrees,
            Double baselinePitchDegrees,
            Double capsuleMotilityBaseline) {
    }

    public record RealismRequest(
            Double noiseStdDevG,
            Double sampleDropoutRate,
            Double missingWindowRate,
            Double eventRate) {
    }
}
