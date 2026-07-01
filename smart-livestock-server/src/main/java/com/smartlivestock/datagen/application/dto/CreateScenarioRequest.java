package com.smartlivestock.datagen.application.dto;

public record CreateScenarioRequest(
        String name, String type, Double penetrationRate,
        String windowStart, String windowEnd, Integer intervalSeconds
) {}
