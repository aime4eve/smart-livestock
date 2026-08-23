package com.smartlivestock.datagen.domain.model.behavior;

import java.util.Map;

public record BehaviorFeature(Map<String, Object> values) {
    public BehaviorFeature {
        values = values == null ? Map.of() : Map.copyOf(values);
    }
}
