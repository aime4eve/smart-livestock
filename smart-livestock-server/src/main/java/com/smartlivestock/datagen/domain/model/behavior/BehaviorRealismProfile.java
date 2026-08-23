package com.smartlivestock.datagen.domain.model.behavior;

public record BehaviorRealismProfile(
        double noiseStdDevG,
        double sampleDropoutRate,
        double missingWindowRate,
        double eventRate) {
    public BehaviorRealismProfile {
        if (noiseStdDevG < 0 || noiseStdDevG > 0.2
                || sampleDropoutRate < 0 || sampleDropoutRate >= 1
                || missingWindowRate < 0 || missingWindowRate >= 1
                || eventRate < 0 || eventRate >= 1) {
            throw new IllegalArgumentException("Behavior realism profile is out of range");
        }
    }
}
