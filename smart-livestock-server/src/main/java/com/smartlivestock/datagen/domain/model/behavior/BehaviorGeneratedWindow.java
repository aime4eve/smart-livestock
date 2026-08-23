package com.smartlivestock.datagen.domain.model.behavior;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record BehaviorGeneratedWindow(
        UUID episodeId,
        BehaviorSubject subject,
        Instant startAt,
        Instant endAt,
        BehaviorDominant dominantBehavior,
        InputQuality inputQuality,
        SamplingMode samplingMode,
        Map<BehaviorFacet, BehaviorLabelValue> labels,
        BehaviorFeature feature) {
    public BehaviorGeneratedWindow {
        labels = labels == null ? Map.of() : Map.copyOf(labels);
    }
}
