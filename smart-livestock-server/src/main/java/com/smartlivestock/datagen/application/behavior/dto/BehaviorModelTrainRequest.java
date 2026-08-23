package com.smartlivestock.datagen.application.behavior.dto;

public record BehaviorModelTrainRequest(
        String requestedCapability,
        String modelName,
        String modelVersion,
        Integer minimumSupport,
        Integer randomSeed) {
}
