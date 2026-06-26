package com.smartlivestock.datagen.application.dto;

import java.time.Instant;
import java.util.List;

public record EvaluationReport(
        Instant windowStart, Instant windowEnd,
        int totalLabels, int totalScores,
        // HEALTH dimension
        double overallPrecision, double overallRecall, double overallF1,
        List<MetricResult> healthPerPattern,
        // FENCE dimension
        int fenceInjectedBreachCount, int fenceInjectedApproachCount,
        int fenceDetectedBreachCount, int fenceDetectedApproachCount,
        List<MetricResult> fenceMetrics
) {}
