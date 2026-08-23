package com.smartlivestock.datagen.application.behavior.dto;

public record BehaviorBoundaryMetrics(
        long groundTruthTransitions,
        long predictedTransitions,
        long matchedTransitions,
        double precision,
        double recall,
        double f1) {
}
