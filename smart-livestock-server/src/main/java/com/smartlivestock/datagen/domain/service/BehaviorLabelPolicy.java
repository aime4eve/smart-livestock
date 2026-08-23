package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFacet;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;

import java.util.EnumMap;
import java.util.Map;
import java.util.Random;

public class BehaviorLabelPolicy {
    public Map<BehaviorFacet, BehaviorLabelValue> labels(
            BehaviorDominant dominant,
            BehaviorLabelValue event,
            Random random) {
        Map<BehaviorFacet, BehaviorLabelValue> labels = new EnumMap<>(BehaviorFacet.class);
        labels.put(BehaviorFacet.POSTURE, posture(dominant, random));
        labels.put(BehaviorFacet.ORAL_ACTIVITY, oralActivity(dominant));
        labels.put(BehaviorFacet.LOCOMOTION, locomotion(dominant));
        labels.put(BehaviorFacet.EVENT, event == null ? BehaviorLabelValue.NONE : event);
        return labels;
    }

    private BehaviorLabelValue posture(BehaviorDominant dominant, Random random) {
        return switch (dominant) {
            case LYING -> BehaviorLabelValue.LYING;
            case RUMINATING -> random.nextBoolean()
                    ? BehaviorLabelValue.LYING
                    : BehaviorLabelValue.STANDING;
            case FEEDING, WALKING, OTHER -> BehaviorLabelValue.STANDING;
        };
    }

    private BehaviorLabelValue oralActivity(BehaviorDominant dominant) {
        return switch (dominant) {
            case RUMINATING -> BehaviorLabelValue.RUMINATING;
            case FEEDING -> BehaviorLabelValue.FEEDING;
            case LYING, WALKING, OTHER -> BehaviorLabelValue.NONE;
        };
    }

    private BehaviorLabelValue locomotion(BehaviorDominant dominant) {
        return switch (dominant) {
            case WALKING -> BehaviorLabelValue.WALKING;
            case LYING, RUMINATING, FEEDING, OTHER -> BehaviorLabelValue.STATIONARY;
        };
    }
}
