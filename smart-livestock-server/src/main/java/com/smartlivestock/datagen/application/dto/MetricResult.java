package com.smartlivestock.datagen.application.dto;

import com.smartlivestock.datagen.domain.model.AnomalyPattern;

public record MetricResult(
        AnomalyPattern pattern,
        int truePositive, int falsePositive,
        int falseNegative, int trueNegative,
        double precision, double recall, double f1
) {}
