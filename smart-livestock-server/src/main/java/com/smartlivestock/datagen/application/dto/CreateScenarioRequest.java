package com.smartlivestock.datagen.application.dto;

public record CreateScenarioRequest(
        String name,
        String scenarioType,
        String pattern,
        Double penetrationRate,
        String windowStart,
        String windowEnd,
        Integer intervalSeconds
) {}
