package com.smartlivestock.datagen.application.dto;

import com.smartlivestock.datagen.domain.model.ScenarioType;

public record MetricResult(
        ScenarioType type,
        int truePositive, int falsePositive,
        int falseNegative, int trueNegative,
        double precision, double recall, double f1
) {}
