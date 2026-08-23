package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeature;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorTransitionMatrix;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Random;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BehaviorWaveformGeneratorTest {
    private final BehaviorWaveformGenerator generator = new BehaviorWaveformGenerator(
            new BehaviorFeatureValidator());

    @Test
    void ruminationAndFeedingHaveDistinctProtocolFeatures() {
        BehaviorScenarioDefinition scenario = scenario();
        BehaviorFeature rumination = generator.generate(
                scenario,
                subject(),
                BehaviorDominant.RUMINATING,
                BehaviorLabelValue.NONE,
                new Random(101));
        BehaviorFeature feeding = generator.generate(
                scenario,
                subject(),
                BehaviorDominant.FEEDING,
                BehaviorLabelValue.NONE,
                new Random(202));

        double ruminationFrequency = feature(rumination, "dominant_freq_hz");
        double feedingEntropy = feature(feeding, "spectral_entropy");
        double ruminationEntropy = feature(rumination, "spectral_entropy");
        long feedingBursts = number(feeding, "burst_count");
        long ruminationBursts = number(rumination, "burst_count");

        assertTrue(ruminationFrequency >= 1.0 && ruminationFrequency <= 1.5,
                "rumination frequency was " + ruminationFrequency);
        assertTrue(ruminationEntropy < feedingEntropy);
        assertTrue(feedingBursts > ruminationBursts);
    }

    @Test
    void walkingIsDistinctFromLying() {
        BehaviorScenarioDefinition scenario = scenario();
        BehaviorFeature walking = generator.generate(
                scenario, subject(), BehaviorDominant.WALKING,
                BehaviorLabelValue.NONE, new Random(303));
        BehaviorFeature lying = generator.generate(
                scenario, subject(), BehaviorDominant.LYING,
                BehaviorLabelValue.NONE, new Random(404));

        assertTrue(feature(walking, "mean_speed_mps") > feature(lying, "mean_speed_mps"));
        assertTrue(number(walking, "step_count") > number(lying, "step_count"));
        assertTrue(feature(walking, "spectral_power_ratio") > feature(lying, "spectral_power_ratio"));
    }

    @Test
    void missingWindowUsesUnknownQualityAndCompleteMask() {
        BehaviorFeature feature = generator.generateMissing();

        assertEquals(0, feature.values().get("sample_count"));
        assertEquals(7500, feature.values().get("expected_sample_count"));
        assertEquals((1 << 25) - 1, feature.values().get("missing_feature_mask"));
        assertEquals(InputQuality.UNKNOWN, InputQuality.UNKNOWN);
    }

    private BehaviorScenarioDefinition scenario() {
        return new BehaviorScenarioDefinition(
                "feature-smoke",
                1,
                "behavior-generator-v1",
                Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-23T00:05:00Z"),
                List.of(subject()),
                BehaviorTransitionMatrix.defaultMatrix(),
                List.of(1.0, 1.0, 1.0, 1.0, 1.0),
                new BehaviorRealismProfile(0.001, 0, 0, 0));
    }

    private BehaviorSubject subject() {
        return new BehaviorSubject(1L, 1L, 1L, 5L, 8, -4, 3.2);
    }

    private double feature(BehaviorFeature feature, String name) {
        return ((Number) feature.values().get(name)).doubleValue();
    }

    private long number(BehaviorFeature feature, String name) {
        return ((Number) feature.values().get(name)).longValue();
    }
}
