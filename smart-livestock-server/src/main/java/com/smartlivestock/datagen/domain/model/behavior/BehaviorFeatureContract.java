package com.smartlivestock.datagen.domain.model.behavior;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;

public final class BehaviorFeatureContract {
    public static final String VERSION_V1 = "v1";

    private final String featureVersion;
    private final List<BehaviorFeatureField> fields;
    private final String schemaHash;

    private BehaviorFeatureContract(String featureVersion, List<BehaviorFeatureField> fields) {
        this.featureVersion = featureVersion;
        this.fields = List.copyOf(fields);
        this.schemaHash = sha256(canonicalDefinition());
    }

    public static BehaviorFeatureContract of(String featureVersion, List<BehaviorFeatureField> fields) {
        return new BehaviorFeatureContract(featureVersion, fields);
    }

    public static BehaviorFeatureContract v1() {
        return V1;
    }

    public String featureVersion() {
        return featureVersion;
    }

    public List<BehaviorFeatureField> fields() {
        return fields;
    }

    public String schemaHash() {
        return schemaHash;
    }

    public String canonicalDefinition() {
        StringBuilder json = new StringBuilder();
        json.append("{\"featureVersion\":\"").append(featureVersion).append("\",\"fields\":[");
        for (int i = 0; i < fields.size(); i++) {
            BehaviorFeatureField field = fields.get(i);
            if (i > 0) {
                json.append(',');
            }
            json.append("{\"name\":\"").append(field.name())
                    .append("\",\"primitive\":\"").append(field.primitive())
                    .append("\",\"unit\":\"").append(field.unit())
                    .append("\",\"required\":").append(field.required())
                    .append(",\"minimum\":\"").append(field.minimum().toPlainString())
                    .append("\",\"maximum\":\"").append(field.maximum().toPlainString())
                    .append("\",\"missingBitIndex\":").append(field.missingBitIndex())
                    .append('}');
        }
        json.append("]}");
        return json.toString();
    }

    private static String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is unavailable", e);
        }
    }

    private static final BehaviorFeatureContract V1 = new BehaviorFeatureContract(
            VERSION_V1,
            List.of(
                    BehaviorFeatureField.core(
                            "sample_count", BehaviorPrimitive.INTEGER, "samples",
                            BigDecimal.ZERO, BigDecimal.valueOf(100_000_000L)),
                    BehaviorFeatureField.core(
                            "expected_sample_count", BehaviorPrimitive.INTEGER, "samples",
                            BigDecimal.ZERO, BigDecimal.valueOf(100_000_000L)),
                    BehaviorFeatureField.core(
                            "missing_feature_mask", BehaviorPrimitive.BITMASK, "bits",
                            BigDecimal.ZERO, BigDecimal.valueOf((1 << 26) - 1)),
                    decimal("accel_mean_x", "g", -16, 16, 0),
                    decimal("accel_mean_y", "g", -16, 16, 1),
                    decimal("accel_mean_z", "g", -16, 16, 2),
                    decimal("accel_std_x", "g", 0, 16, 3),
                    decimal("accel_std_y", "g", 0, 16, 4),
                    decimal("accel_std_z", "g", 0, 16, 5),
                    decimal("roll_mean", "degrees", -180, 180, 6),
                    decimal("roll_std", "degrees", 0, 180, 7),
                    decimal("pitch_mean", "degrees", -180, 180, 8),
                    decimal("pitch_std", "degrees", 0, 180, 9),
                    decimal("dominant_freq_hz", "Hz", 0, 12.5, 10),
                    decimal("spectral_power_ratio", "ratio", 0, 1, 11),
                    decimal("spectral_entropy", "normalized_entropy", 0, 1, 12),
                    integer("burst_count", "events", 0, 100_000_000L, 13),
                    decimal("zero_crossing_rate", "ratio", 0, 1, 14),
                    integer("step_count", "steps", 0, 100_000_000L, 15),
                    decimal("distance_meters", "m", 0, 100_000, 16),
                    decimal("mean_speed_mps", "m/s", 0, 10, 17),
                    integer("activity_class_counts.rest", "samples", 0, 100_000_000L, 18),
                    integer("activity_class_counts.light", "samples", 0, 100_000_000L, 19),
                    integer("activity_class_counts.active", "samples", 0, 100_000_000L, 20),
                    integer("activity_class_counts.intense", "samples", 0, 100_000_000L, 21),
                    decimal("capsule_motility_mean", "index", 0, 100, 22),
                    decimal("capsule_motility_std", "index", 0, 100, 23),
                    integer("posture_transition_count", "events", 0, 100_000_000L, 24)));

    private static BehaviorFeatureField decimal(
            String name, String unit, double min, double max, int missingBitIndex) {
        return BehaviorFeatureField.optionalByMask(
                name,
                BehaviorPrimitive.DECIMAL,
                unit,
                BigDecimal.valueOf(min),
                BigDecimal.valueOf(max),
                missingBitIndex);
    }

    private static BehaviorFeatureField integer(
            String name, String unit, long min, long max, int missingBitIndex) {
        return BehaviorFeatureField.optionalByMask(
                name,
                BehaviorPrimitive.INTEGER,
                unit,
                BigDecimal.valueOf(min),
                BigDecimal.valueOf(max),
                missingBitIndex);
    }

    public static List<BehaviorFeatureField> mutableV1Fields() {
        return new ArrayList<>(V1.fields);
    }
}
