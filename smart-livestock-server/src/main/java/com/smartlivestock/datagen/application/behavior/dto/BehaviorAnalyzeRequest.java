package com.smartlivestock.datagen.application.behavior.dto;

public record BehaviorAnalyzeRequest(
        String requestedCapability,
        String modelName,
        String modelVersion) {
}
