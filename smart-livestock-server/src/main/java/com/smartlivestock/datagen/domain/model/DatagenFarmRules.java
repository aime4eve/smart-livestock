package com.smartlivestock.datagen.domain.model;

public record DatagenFarmRules(
        int trackerIntervalSeconds,
        int capsuleIntervalSeconds,
        double fenceExcursionProbability,
        int fenceExcursionMinMinutes,
        int fenceExcursionMaxMinutes,
        double healthEventProbability,
        int feverDurationMinMinutes,
        int feverDurationMaxMinutes,
        int motilityDurationMinMinutes,
        int motilityDurationMaxMinutes) {

    public static DatagenFarmRules defaults() {
        return new DatagenFarmRules(
                300, 900,
                0.02, 10, 30,
                0.005, 240, 480, 480, 720);
    }
}
