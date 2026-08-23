package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.domain.model.behavior.BehaviorDominant;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorFeatureContract;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedEpisode;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedWindow;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGenerationManifest;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorLabelValue;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import com.smartlivestock.datagen.domain.model.behavior.SamplingMode;

import java.nio.charset.StandardCharsets;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

public class BehaviorDatasetGenerator {
    private final BehaviorWaveformGenerator waveformGenerator;
    private final BehaviorLabelPolicy labelPolicy = new BehaviorLabelPolicy();

    public BehaviorDatasetGenerator(BehaviorWaveformGenerator waveformGenerator) {
        this.waveformGenerator = waveformGenerator;
    }

    public BehaviorGeneratedDataset generate(BehaviorScenarioDefinition scenario) {
        UUID datasetId = deterministicId(fullScenarioIdentity(scenario));
        int expectedWindowsPerSubject = scenario.expectedWindows();
        List<BehaviorGeneratedEpisode> episodes = new ArrayList<>();
        List<BehaviorGeneratedWindow> windows = new ArrayList<>();

        for (BehaviorSubject subject : scenario.subjects()) {
            Random scheduleRandom = new Random(stableSeed(
                    scenario.seed() + ":schedule:" + subject.deviceId() + ":" + subject.livestockId()));
            BehaviorDominant currentDominant = null;
            UUID currentEpisodeId = null;
            Instant currentEpisodeStart = null;
            Instant currentEpisodeEnd = null;

            for (int i = 0; i < expectedWindowsPerSubject; i++) {
                Instant windowStart = scenario.startAt().plusSeconds((long) i * 300);
                Instant windowEnd = windowStart.plusSeconds(300);

                if (scheduleRandom.nextDouble() < scenario.realismProfile().missingWindowRate()) {
                    finalizeEpisode(episodes, subject, currentDominant, currentEpisodeId,
                            currentEpisodeStart, windowStart);
                    currentDominant = null;
                    currentEpisodeId = null;
                    currentEpisodeStart = null;
                    currentEpisodeEnd = null;

                    UUID gapEpisodeId = deterministicId(datasetId + ":gap:" + subject.deviceId()
                            + ":" + windowStart);
                    episodes.add(new BehaviorGeneratedEpisode(
                            gapEpisodeId, subject, BehaviorDominant.OTHER, windowStart, windowEnd));
                    windows.add(new BehaviorGeneratedWindow(
                            gapEpisodeId,
                            subject,
                            windowStart,
                            windowEnd,
                            BehaviorDominant.OTHER,
                            InputQuality.UNKNOWN,
                            SamplingMode.PROTOCOL_SUMMARY,
                            Map.of(),
                            waveformGenerator.generateMissing()));
                    continue;
                }

                BehaviorDominant dominant = currentDominant == null
                        ? initialDominant(scenario, scheduleRandom)
                        : scenario.transitionMatrix().next(currentDominant, scheduleRandom);
                if (currentDominant == null || dominant != currentDominant) {
                    finalizeEpisode(episodes, subject, currentDominant, currentEpisodeId,
                            currentEpisodeStart, windowStart);
                    currentDominant = dominant;
                    currentEpisodeStart = windowStart;
                    currentEpisodeId = deterministicId(datasetId + ":episode:" + subject.deviceId()
                            + ":" + windowStart + ":" + dominant);
                }
                currentEpisodeEnd = windowEnd;

                BehaviorLabelValue event = nextEvent(scheduleRandom, scenario.realismProfile());
                Random waveformRandom = new Random(stableSeed(
                        scenario.seed() + ":waveform:" + subject.deviceId() + ":" + windowStart));
                var feature = waveformGenerator.generate(
                        scenario, subject, dominant, event, waveformRandom);
                Random labelRandom = new Random(stableSeed(
                        scenario.seed() + ":labels:" + subject.deviceId() + ":" + windowStart));
                var labels = labelPolicy.labels(dominant, event, labelRandom);
                windows.add(new BehaviorGeneratedWindow(
                        currentEpisodeId,
                        subject,
                        windowStart,
                        windowEnd,
                        dominant,
                        InputQuality.FULL_0X40,
                        SamplingMode.PROTOCOL_SUMMARY,
                            labels,
                        feature));
            }

            finalizeEpisode(episodes, subject, currentDominant, currentEpisodeId,
                    currentEpisodeStart, currentEpisodeEnd == null ? scenario.endAt() : currentEpisodeEnd);
        }

        BehaviorFeatureContract contract = BehaviorFeatureContract.v1();
        BehaviorGenerationManifest manifest = new BehaviorGenerationManifest(
                datasetId,
                scenario.scenarioId(),
                scenario.seed(),
                scenario.generatorVersion(),
                scenario.startAt(),
                scenario.endAt(),
                scenario.subjects().size(),
                expectedWindowsPerSubject * scenario.subjects().size(),
                windows.size(),
                episodes.size(),
                contract.featureVersion(),
                contract.schemaHash());
        return new BehaviorGeneratedDataset(manifest, episodes, windows);
    }

    private BehaviorDominant initialDominant(
            BehaviorScenarioDefinition scenario, Random random) {
        double selector = random.nextDouble();
        double total = scenario.initialWeights().stream()
                .mapToDouble(Double::doubleValue).sum();
        double cumulative = 0;
        BehaviorDominant[] values = BehaviorDominant.values();
        for (int i = 0; i < values.length; i++) {
            cumulative += scenario.initialWeights().get(i) / total;
            if (selector < cumulative) {
                return values[i];
            }
        }
        return BehaviorDominant.OTHER;
    }

    private BehaviorLabelValue nextEvent(Random random, BehaviorRealismProfile profile) {
        if (random.nextDouble() >= profile.eventRate()) {
            return BehaviorLabelValue.NONE;
        }
        return random.nextBoolean()
                ? BehaviorLabelValue.CALVING_RISK
                : BehaviorLabelValue.ESTRUS_LIKE;
    }

    private void finalizeEpisode(
            List<BehaviorGeneratedEpisode> episodes,
            BehaviorSubject subject,
            BehaviorDominant dominant,
            UUID episodeId,
            Instant start,
            Instant end) {
        if (dominant == null || episodeId == null || start == null || end == null || !end.isAfter(start)) {
            return;
        }
        episodes.add(new BehaviorGeneratedEpisode(episodeId, subject, dominant, start, end));
    }

    private String fullScenarioIdentity(BehaviorScenarioDefinition scenario) {
        StringBuilder identity = new StringBuilder()
                .append(scenario.scenarioId()).append('|')
                .append(scenario.seed()).append('|')
                .append(scenario.generatorVersion()).append('|')
                .append(scenario.startAt()).append('|')
                .append(scenario.endAt()).append('|')
                .append(BehaviorFeatureContract.v1().schemaHash()).append('|')
                .append("initial=");
        for (double weight : scenario.initialWeights()) {
            identity.append(canonicalDecimal(weight)).append(',');
        }
        identity.append("|transitions=");
        Map<BehaviorDominant, Map<BehaviorDominant, Double>> weights =
                scenario.transitionMatrix().weights();
        for (BehaviorDominant from : BehaviorDominant.values()) {
            for (BehaviorDominant to : BehaviorDominant.values()) {
                identity.append(from.name())
                        .append('>')
                        .append(to.name())
                        .append('=')
                        .append(canonicalDecimal(weights.get(from).get(to)))
                        .append(',');
            }
        }
        identity.append("|realism=")
                .append(canonicalDecimal(scenario.realismProfile().noiseStdDevG())).append(',')
                .append(canonicalDecimal(scenario.realismProfile().sampleDropoutRate())).append(',')
                .append(canonicalDecimal(scenario.realismProfile().missingWindowRate())).append(',')
                .append(canonicalDecimal(scenario.realismProfile().eventRate()))
                .append("|subjects=");
        for (BehaviorSubject subject : scenario.subjects()) {
            identity.append(subject.tenantId()).append(',')
                    .append(subject.farmId()).append(',')
                    .append(subject.livestockId()).append(',')
                    .append(subject.deviceId()).append(',')
                    .append(canonicalDecimal(subject.baselineRollDegrees())).append(',')
                    .append(canonicalDecimal(subject.baselinePitchDegrees())).append(',')
                    .append(canonicalDecimal(subject.capsuleMotilityBaseline())).append(';');
        }
        return identity.toString();
    }

    private String canonicalDecimal(double value) {
        if (value == 0) {
            value = 0;
        }
        return BigDecimal.valueOf(value)
                .setScale(6, RoundingMode.HALF_UP)
                .toPlainString();
    }

    private UUID deterministicId(String value) {
        return UUID.nameUUIDFromBytes(value.getBytes(StandardCharsets.UTF_8));
    }

    private long stableSeed(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            long result = 0;
            for (int i = 0; i < 8; i++) {
                result = (result << 8) | (bytes[i] & 0xff);
            }
            return result;
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is unavailable", e);
        }
    }
}
