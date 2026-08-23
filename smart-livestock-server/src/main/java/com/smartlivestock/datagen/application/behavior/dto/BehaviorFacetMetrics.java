package com.smartlivestock.datagen.application.behavior.dto;

import java.util.List;

public record BehaviorFacetMetrics(
        String facet,
        double hammingLoss,
        int missingLabelWindows,
        List<BehaviorFacetLabelMetric> labels) {

    public record BehaviorFacetLabelMetric(
            String label,
            long truePositive,
            long falsePositive,
            long falseNegative,
            long trueNegative,
            long support,
            double precision,
            double recall,
            double f1) {
    }
}
