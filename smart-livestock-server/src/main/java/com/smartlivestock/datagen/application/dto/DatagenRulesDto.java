package com.smartlivestock.datagen.application.dto;

public record DatagenRulesDto(
        int trackerIntervalSeconds,
        int capsuleIntervalSeconds,
        double fenceExcursionProbability,
        int fenceExcursionMinMinutes,
        int fenceExcursionMaxMinutes,
        double healthEventProbability,
        int feverDurationMinMinutes,
        int feverDurationMaxMinutes,
        int motilityDurationMinMinutes,
        int motilityDurationMaxMinutes) {}
