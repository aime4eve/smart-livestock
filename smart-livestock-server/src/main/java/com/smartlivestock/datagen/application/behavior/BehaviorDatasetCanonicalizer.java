package com.smartlivestock.datagen.application.behavior;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFacet;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedEpisode;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedWindow;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGenerationManifest;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;

@Component
public class BehaviorDatasetCanonicalizer {
    public String canonicalScenario(BehaviorScenarioDefinition scenario) {
        StringBuilder json = new StringBuilder();
        json.append("{\"kind\":\"behavior_scenario\"");
        appendField(json, "scenario_id", scenario.scenarioId());
        appendField(json, "seed", scenario.seed());
        appendField(json, "generator_version", scenario.generatorVersion());
        appendField(json, "start_at", scenario.startAt().toString());
        appendField(json, "end_at", scenario.endAt().toString());
        appendField(json, "feature_version", BehaviorFeatureContract.v1().featureVersion());
        appendField(json, "feature_schema_hash", BehaviorFeatureContract.v1().schemaHash());
        json.append(",\"initial_weights\":[");
        for (int i = 0; i < scenario.initialWeights().size(); i++) {
            if (i > 0) json.append(',');
            appendDecimal(json, scenario.initialWeights().get(i));
        }
        json.append("],\"transition_matrix\":{");
        Map<BehaviorDominant, Map<BehaviorDominant, Double>> weights =
                scenario.transitionMatrix().weights();
        for (int i = 0; i < BehaviorDominant.values().length; i++) {
            BehaviorDominant from = BehaviorDominant.values()[i];
            if (i > 0) json.append(',');
            json.append("\"").append(from).append("\":{");
            for (int j = 0; j < BehaviorDominant.values().length; j++) {
                BehaviorDominant to = BehaviorDominant.values()[j];
                if (j > 0) json.append(',');
                json.append("\"").append(to).append("\":");
                appendDecimal(json, weights.get(from).get(to));
            }
            json.append('}');
        }
        json.append("},\"realism_profile\":{");
        appendField(json, "noise_std_dev_g", scenario.realismProfile().noiseStdDevG());
        appendField(json, "sample_dropout_rate", scenario.realismProfile().sampleDropoutRate());
        appendField(json, "missing_window_rate", scenario.realismProfile().missingWindowRate());
        appendField(json, "event_rate", scenario.realismProfile().eventRate());
        removeTrailingComma(json);
        json.append("},\"subjects\":[");
        for (int i = 0; i < scenario.subjects().size(); i++) {
            if (i > 0) json.append(',');
            appendSubject(json, scenario.subjects().get(i));
        }
        json.append("]}");
        return json.toString();
    }

    public String canonicalDataset(BehaviorGeneratedDataset dataset) {
        StringBuilder json = new StringBuilder();
        json.append("{\"kind\":\"behavior_dataset\"");
        appendManifest(json, dataset.manifest());
        json.append(",\"episodes\":[");
        for (int i = 0; i < dataset.episodes().size(); i++) {
            if (i > 0) json.append(',');
            appendEpisode(json, dataset.episodes().get(i));
        }
        json.append("],\"windows\":[");
        for (int i = 0; i < dataset.windows().size(); i++) {
            if (i > 0) json.append(',');
            appendWindow(json, dataset.windows().get(i));
        }
        json.append("]}");
        return json.toString();
    }

    public String semanticDigest(BehaviorGeneratedDataset dataset) {
        return sha256(canonicalDataset(dataset));
    }

    public String scenarioDigest(BehaviorScenarioDefinition scenario) {
        return sha256(canonicalScenario(scenario));
    }

    private void appendManifest(StringBuilder json, BehaviorGenerationManifest manifest) {
        appendField(json, "dataset_id", manifest.datasetId().toString());
        appendField(json, "scenario_id", manifest.scenarioId());
        appendField(json, "seed", manifest.seed());
        appendField(json, "generator_version", manifest.generatorVersion());
        appendField(json, "start_at", manifest.startAt().toString());
        appendField(json, "end_at", manifest.endAt().toString());
        appendField(json, "subject_count", manifest.subjectCount());
        appendField(json, "expected_window_count", manifest.expectedWindowCount());
        appendField(json, "generated_window_count", manifest.generatedWindowCount());
        appendField(json, "episode_count", manifest.episodeCount());
        appendField(json, "feature_version", manifest.featureVersion());
        appendField(json, "feature_schema_hash", manifest.featureSchemaHash());
    }

    private void appendEpisode(StringBuilder json, BehaviorGeneratedEpisode episode) {
        json.append("{\"episode_id\":\"").append(episode.id()).append('"');
        appendField(json, "device_id", episode.subject().deviceId());
        appendField(json, "livestock_id", episode.subject().livestockId());
        appendField(json, "dominant_behavior", episode.dominantBehavior().name());
        appendField(json, "start_at", episode.startAt().toString());
        appendField(json, "end_at", episode.endAt().toString());
        json.append('}');
    }

    private void appendWindow(StringBuilder json, BehaviorGeneratedWindow window) {
        json.append("{\"episode_id\":\"").append(window.episodeId()).append('"');
        appendField(json, "device_id", window.subject().deviceId());
        appendField(json, "livestock_id", window.subject().livestockId());
        appendField(json, "start_at", window.startAt().toString());
        appendField(json, "end_at", window.endAt().toString());
        appendField(json, "dominant_behavior", window.dominantBehavior().name());
        appendField(json, "input_quality", window.inputQuality().name());
        appendField(json, "sampling_mode", window.samplingMode().name());
        json.append(",\"labels\":{");
        BehaviorFacet[] facets = BehaviorFacet.values();
        boolean wroteLabel = false;
        for (int i = 0; i < facets.length; i++) {
            BehaviorFacet facet = facets[i];
            var label = window.labels().get(facet);
            if (label == null) {
                continue;
            }
            if (wroteLabel) {
                json.append(',');
            }
            json.append("\"").append(facet.name()).append("\":\"").append(label.name()).append("\"");
            wroteLabel = true;
        }
        json.append("},\"features\":{");
        BehaviorFeatureContract contract = BehaviorFeatureContract.v1();
        for (var field : contract.fields()) {
            Object value = window.feature().values().get(field.name());
            if (value == null) {
                continue;
            }
            appendField(json, field.name(), value);
        }
        json.append("}}");
    }

    private void appendSubject(StringBuilder json, BehaviorSubject subject) {
        json.append('{');
        appendField(json, "tenant_id", subject.tenantId());
        appendField(json, "farm_id", subject.farmId());
        appendField(json, "livestock_id", subject.livestockId());
        appendField(json, "device_id", subject.deviceId());
        appendField(json, "baseline_roll_degrees", subject.baselineRollDegrees());
        appendField(json, "baseline_pitch_degrees", subject.baselinePitchDegrees());
        appendField(json, "capsule_motility_baseline", subject.capsuleMotilityBaseline());
        json.append('}');
    }

    private void appendField(StringBuilder json, String name, Object value) {
        json.append(",\"").append(name).append("\":");
        if (value instanceof Double || value instanceof Float || value instanceof BigDecimal) {
            appendDecimal(json, ((Number) value).doubleValue());
        } else if (value instanceof Number number) {
            json.append(number.longValue());
        } else if (value != null) {
            json.append(quote(value.toString()));
        } else {
            json.append("null");
        }
    }

    private void appendDecimal(StringBuilder json, double value) {
        if (value == 0) value = 0;
        json.append(quote(BigDecimal.valueOf(value)
                .setScale(6, RoundingMode.HALF_UP)
                .toPlainString()));
    }

    private String quote(String value) {
        return "\"" + value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n") + "\"";
    }

    private void removeTrailingComma(StringBuilder json) {
        int length = json.length();
        if (length > 0 && json.charAt(length - 1) == ',') {
            json.setLength(length - 1);
        }
    }

    private String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(
                    digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is unavailable", e);
        }
    }
}
