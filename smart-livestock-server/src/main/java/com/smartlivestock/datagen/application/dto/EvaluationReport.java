package com.smartlivestock.datagen.application.dto;

import com.smartlivestock.datagen.domain.model.AnomalyPattern;

import java.time.Instant;
import java.util.List;

public record EvaluationReport(
        Instant windowStart, Instant windowEnd,
        int totalLabels, int totalScores,
        double overallPrecision, double overallRecall, double overallF1,
        List<MetricResult> healthPerPattern,
        int fenceInjectedCount,
        List<MetricResult> fenceMetrics
) {}
