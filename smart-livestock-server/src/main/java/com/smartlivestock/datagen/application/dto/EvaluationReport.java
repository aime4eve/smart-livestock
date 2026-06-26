package com.smartlivestock.datagen.application.dto;

import java.time.Instant;
import java.util.List;

public record EvaluationReport(
        Instant windowStart, Instant windowEnd,
        int totalLabels, int totalScores,
        double overallPrecision, double overallRecall, double overallF1,
        List<MetricResult> perPatternMetrics
) {}
