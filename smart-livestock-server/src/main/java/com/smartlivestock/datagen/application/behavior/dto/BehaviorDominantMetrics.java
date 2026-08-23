package com.smartlivestock.datagen.application.behavior.dto;

import java.util.List;
import java.util.Map;

public record BehaviorDominantMetrics(
        int evaluatedWindows,
        double accuracy,
        double top2Accuracy,
        double macroPrecision,
        double macroRecall,
        double macroF1,
        double weightedF1,
        double imbalanceRatio,
        Map<String, Map<String, Long>> confusionMatrix,
        Map<String, Long> nearClassConfusion,
        List<BehaviorClassMetric> classMetrics) {

    public record BehaviorClassMetric(
            String label,
            long support,
            long predictedCount,
            double precision,
            double recall,
            double f1) {
    }
}
