package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorFacet;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeature;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class BehaviorFeatureValidatorTest {
    private final BehaviorFeatureValidator validator = new BehaviorFeatureValidator();

    @Test
    void fullFeatureSetValidates() {
        BehaviorFeature feature = validator.validate(
                BehaviorFeatureContract.v1(),
                fullValues(),
                InputQuality.FULL_0X40);

        assertEquals(7500, feature.values().get("sample_count"));
        assertEquals(1.25, feature.values().get("dominant_freq_hz"));
    }

    @Test
    void fullInputCannotDeclareMissingFields() {
        Map<String, Object> values = fullValues();
        values.put("missing_feature_mask", 1);

        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), values, InputQuality.FULL_0X40));
    }

    @Test
    void partialInputMayOmitFieldsOnlyThroughMask() {
        Map<String, Object> values = fullValues();
        values.put("spectral_entropy", null);
        values.put("missing_feature_mask", 1 << 12);

        BehaviorFeature feature = validator.validate(
                BehaviorFeatureContract.v1(), values, InputQuality.PARTIAL_0X40);
        assertEquals(false, feature.values().containsKey("spectral_entropy"));

        values.put("missing_feature_mask", 0);
        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), values, InputQuality.PARTIAL_0X40));
    }

    @Test
    void rejectsMissingOutOfRangeAndNonIntegerValues() {
        Map<String, Object> missing = fullValues();
        missing.remove("roll_mean");
        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), missing, InputQuality.FULL_0X40));

        Map<String, Object> outOfRange = fullValues();
        outOfRange.put("dominant_freq_hz", 13.0);
        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), outOfRange, InputQuality.FULL_0X40));

        Map<String, Object> nonInteger = fullValues();
        nonInteger.put("step_count", 1.5);
        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), nonInteger, InputQuality.FULL_0X40));

        Map<String, Object> nonFinite = fullValues();
        nonFinite.put("roll_mean", Double.NaN);
        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), nonFinite, InputQuality.FULL_0X40));
    }

    @Test
    void rejectsIncompatibleVersionOrHash() {
        BehaviorFeatureContract contract = BehaviorFeatureContract.v1();
        assertDoesNotThrow(() -> validator.assertCompatible(
                contract, contract.featureVersion(), contract.schemaHash()));
        assertThrows(IllegalArgumentException.class, () -> validator.assertCompatible(
                contract, "v2", contract.schemaHash()));
        assertThrows(IllegalArgumentException.class, () -> validator.assertCompatible(
                contract, contract.featureVersion(), "bad-hash"));
    }

    @Test
    void coarseSnapshotCannotCarryOralLabels() {
        assertThrows(IllegalArgumentException.class, () -> validator.validateLabel(
                BehaviorFacet.ORAL_ACTIVITY,
                BehaviorLabelValue.RUMINATING,
                InputQuality.COARSE_SNAPSHOT));
        assertThrows(IllegalArgumentException.class, () -> validator.validateLabel(
                BehaviorFacet.ORAL_ACTIVITY,
                BehaviorLabelValue.FEEDING,
                InputQuality.COARSE_SNAPSHOT));
        assertDoesNotThrow(() -> validator.validateLabel(
                BehaviorFacet.POSTURE,
                BehaviorLabelValue.LYING,
                InputQuality.COARSE_SNAPSHOT));
    }

    @Test
    void activityCountsCannotExceedSampleCount() {
        Map<String, Object> values = fullValues();
        values.put("activity_class_counts.intense", 7501);

        assertThrows(IllegalArgumentException.class, () -> validator.validate(
                BehaviorFeatureContract.v1(), values, InputQuality.FULL_0X40));
    }

    private static Map<String, Object> fullValues() {
        Map<String, Object> values = new HashMap<>();
        values.put("sample_count", 7500);
        values.put("expected_sample_count", 7500);
        values.put("missing_feature_mask", 0);
        values.put("accel_mean_x", 0.1);
        values.put("accel_mean_y", -0.2);
        values.put("accel_mean_z", 0.98);
        values.put("accel_std_x", 0.02);
        values.put("accel_std_y", 0.03);
        values.put("accel_std_z", 0.04);
        values.put("roll_mean", 12.0);
        values.put("roll_std", 1.0);
        values.put("pitch_mean", -8.0);
        values.put("pitch_std", 0.8);
        values.put("dominant_freq_hz", 1.25);
        values.put("spectral_power_ratio", 0.7);
        values.put("spectral_entropy", 0.25);
        values.put("burst_count", 200);
        values.put("zero_crossing_rate", 0.3);
        values.put("step_count", 300);
        values.put("distance_meters", 220.0);
        values.put("mean_speed_mps", 0.73);
        values.put("activity_class_counts.rest", 3000);
        values.put("activity_class_counts.light", 3000);
        values.put("activity_class_counts.active", 1400);
        values.put("activity_class_counts.intense", 100);
        values.put("capsule_motility_mean", 3.2);
        values.put("capsule_motility_std", 0.4);
        values.put("posture_transition_count", 4);
        return values;
    }
}
