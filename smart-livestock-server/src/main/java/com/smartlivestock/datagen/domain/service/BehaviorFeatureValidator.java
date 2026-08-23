package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorFacet;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeature;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureField;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorPrimitive;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

@Service
public class BehaviorFeatureValidator {
    public BehaviorFeature validate(
            BehaviorFeatureContract contract,
            Map<String, Object> values,
            InputQuality inputQuality) {
        Objects.requireNonNull(contract, "contract must not be null");
        Objects.requireNonNull(inputQuality, "inputQuality must not be null");
        if (values == null) {
            throw new IllegalArgumentException("Feature values must not be null");
        }

        int mask = requireCoreInteger(values, "missing_feature_mask", contract);
        Map<String, Object> normalized = new LinkedHashMap<>();
        normalized.put("missing_feature_mask", mask);
        int sampleCount = requireCoreInteger(values, "sample_count", contract);
        int expectedCount = requireCoreInteger(values, "expected_sample_count", contract);
        normalized.put("sample_count", sampleCount);
        normalized.put("expected_sample_count", expectedCount);
        if (sampleCount < 0 || sampleCount > expectedCount) {
            throw new IllegalArgumentException("sample_count cannot exceed expected_sample_count");
        }

        if (inputQuality == InputQuality.FULL_0X40 && mask != 0) {
            throw new IllegalArgumentException("FULL_0X40 cannot contain missing feature bits");
        }
        if (inputQuality == InputQuality.UNKNOWN && mask == 0) {
            throw new IllegalArgumentException("UNKNOWN input must declare missing feature bits");
        }

        for (BehaviorFeatureField field : contract.fields()) {
            if (field.missingBitIndex() < 0) {
                continue;
            }
            boolean markedMissing = (mask & (1 << field.missingBitIndex())) != 0;
            Object value = values.get(field.name());
            if (value == null) {
                if (!markedMissing) {
                    throw new IllegalArgumentException("Missing feature field: " + field.name());
                }
                continue;
            }
            if (markedMissing) {
                throw new IllegalArgumentException(
                        "Feature field is present but marked missing: " + field.name());
            }
            normalized.put(field.name(), validateValue(field, value));
        }

        validateActivityCounts(normalized);
        return new BehaviorFeature(normalized);
    }

    public void assertCompatible(
            BehaviorFeatureContract expected,
            String featureVersion,
            String schemaHash) {
        if (!expected.featureVersion().equals(featureVersion)
                || !expected.schemaHash().equals(schemaHash)) {
            throw new IllegalArgumentException("Incompatible behavior feature contract");
        }
    }

    public void validateLabel(
            BehaviorFacet facet,
            BehaviorLabelValue label,
            InputQuality inputQuality) {
        if (!facet.supports(label)) {
            throw new IllegalArgumentException("Label is invalid for facet " + facet);
        }
        if (inputQuality == InputQuality.COARSE_SNAPSHOT
                && facet == BehaviorFacet.ORAL_ACTIVITY) {
            throw new IllegalArgumentException("Coarse snapshots cannot carry oral activity labels");
        }
    }

    private int requireCoreInteger(
            Map<String, Object> values,
            String name,
            BehaviorFeatureContract contract) {
        BehaviorFeatureField field = contract.fields().stream()
                .filter(item -> item.name().equals(name))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unknown core feature field: " + name));
        Object value = values.get(name);
        if (!(value instanceof Number number)) {
            throw new IllegalArgumentException("Core feature field must be numeric: " + name);
        }
        return validateValue(field, value).intValue();
    }

    private Number validateValue(BehaviorFeatureField field, Object value) {
        if (!(value instanceof Number number)) {
            throw new IllegalArgumentException("Feature field must be numeric: " + field.name());
        }
        double doubleValue = number.doubleValue();
        if (!Double.isFinite(doubleValue)) {
            throw new IllegalArgumentException("Feature field must be finite: " + field.name());
        }
        BigDecimal decimalValue = BigDecimal.valueOf(doubleValue);
        if (decimalValue.compareTo(field.minimum()) < 0
                || decimalValue.compareTo(field.maximum()) > 0) {
            throw new IllegalArgumentException("Feature field is out of range: " + field.name());
        }
        if (field.primitive() != BehaviorPrimitive.DECIMAL
                && decimalValue.stripTrailingZeros().scale() > 0) {
            throw new IllegalArgumentException(
                    "Feature field must be an integer: " + field.name());
        }
        if (field.primitive() == BehaviorPrimitive.INTEGER) {
            return number.longValue();
        }
        return doubleValue;
    }

    private void validateActivityCounts(Map<String, Object> values) {
        String prefix = "activity_class_counts.";
        long sum = 0;
        for (Map.Entry<String, Object> entry : values.entrySet()) {
            if (entry.getKey().startsWith(prefix)) {
                sum += ((Number) entry.getValue()).longValue();
            }
        }
        long sampleCount = ((Number) values.get("sample_count")).longValue();
        if (sum > sampleCount) {
            throw new IllegalArgumentException("Activity class counts cannot exceed sample_count");
        }
    }
}
