package com.smartlivestock.datagen.application.behavior.dto;

import java.util.List;

public record BehaviorEventMetrics(
        long groundTruthEvents,
        long predictedEvents,
        long matchedEvents,
        double precision,
        double recall,
        double f1,
        List<Long> detectionLatencyWindows,
        long missedEvents) {
}
