package com.smartlivestock.datagen.domain.model.behavior;

import java.util.Set;

public enum BehaviorFacet {
    POSTURE(Set.of(BehaviorLabelValue.LYING, BehaviorLabelValue.STANDING, BehaviorLabelValue.TRANSITION)),
    ORAL_ACTIVITY(Set.of(
            BehaviorLabelValue.RUMINATING,
            BehaviorLabelValue.FEEDING,
            BehaviorLabelValue.NONE,
            BehaviorLabelValue.MIXED)),
    LOCOMOTION(Set.of(
            BehaviorLabelValue.STATIONARY,
            BehaviorLabelValue.WALKING,
            BehaviorLabelValue.HIGH_ACTIVITY)),
    EVENT(Set.of(
            BehaviorLabelValue.NONE,
            BehaviorLabelValue.CALVING_RISK,
            BehaviorLabelValue.ESTRUS_LIKE));

    private final Set<BehaviorLabelValue> allowedValues;

    BehaviorFacet(Set<BehaviorLabelValue> allowedValues) {
        this.allowedValues = allowedValues;
    }

    public Set<BehaviorLabelValue> allowedValues() {
        return allowedValues;
    }

    public boolean supports(BehaviorLabelValue value) {
        return allowedValues.contains(value);
    }
}
