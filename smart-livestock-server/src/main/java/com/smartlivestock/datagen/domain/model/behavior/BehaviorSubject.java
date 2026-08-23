package com.smartlivestock.datagen.domain.model.behavior;

public record BehaviorSubject(
        Long tenantId,
        Long farmId,
        Long livestockId,
        Long deviceId,
        double baselineRollDegrees,
        double baselinePitchDegrees,
        double capsuleMotilityBaseline) {
    public BehaviorSubject {
        if (tenantId == null || farmId == null || livestockId == null || deviceId == null) {
            throw new IllegalArgumentException("Behavior subject scope is incomplete");
        }
        if (baselineRollDegrees < -180 || baselineRollDegrees > 180
                || baselinePitchDegrees < -180 || baselinePitchDegrees > 180
                || capsuleMotilityBaseline < 0 || capsuleMotilityBaseline > 100) {
            throw new IllegalArgumentException("Behavior subject baseline is out of range");
        }
    }
}
