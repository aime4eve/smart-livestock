package com.smartlivestock.datagen.domain.model.behavior;

import java.math.BigDecimal;

public record BehaviorFeatureField(
        String name,
        BehaviorPrimitive primitive,
        String unit,
        boolean required,
        BigDecimal minimum,
        BigDecimal maximum,
        int missingBitIndex) {
    public BehaviorFeatureField {
        if (missingBitIndex >= 0) {
            required = true;
        }
    }

    public static BehaviorFeatureField core(
            String name,
            BehaviorPrimitive primitive,
            String unit,
            BigDecimal minimum,
            BigDecimal maximum) {
        return new BehaviorFeatureField(name, primitive, unit, true, minimum, maximum, -1);
    }

    public static BehaviorFeatureField optionalByMask(
            String name,
            BehaviorPrimitive primitive,
            String unit,
            BigDecimal minimum,
            BigDecimal maximum,
            int missingBitIndex) {
        return new BehaviorFeatureField(name, primitive, unit, true, minimum, maximum, missingBitIndex);
    }
}
