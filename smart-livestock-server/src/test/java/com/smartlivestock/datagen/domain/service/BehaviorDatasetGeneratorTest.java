package com.smartlivestock.datagen.domain.service;

import com.smartlivestock.datagen.application.behavior.BehaviorDatasetCanonicalizer;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedDataset;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorGeneratedWindow;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorRealismProfile;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorScenarioDefinition;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorSubject;
import com.smartlivestock.datagen.domain.model.behavior.InputQuality;
import com.smartlivestock.datagen.domain.model.behavior.BehaviorTransitionMatrix;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BehaviorDatasetGeneratorTest {
    private final BehaviorFeatureValidator validator = new BehaviorFeatureValidator();
    private final BehaviorDatasetGenerator generator = new BehaviorDatasetGenerator(
            new BehaviorWaveformGenerator(validator));
    private final BehaviorDatasetCanonicalizer canonicalizer = new BehaviorDatasetCanonicalizer();

    @Test
    void sameCanonicalScenarioProducesIdenticalDataset() {
        BehaviorScenarioDefinition scenario = scenario(1001, false);
        BehaviorGeneratedDataset first = generator.generate(scenario);
        BehaviorGeneratedDataset second = generator.generate(scenario);

        assertEquals(
                canonicalizer.semanticDigest(first),
                canonicalizer.semanticDigest(second));
        assertEquals(
                canonicalizer.canonicalDataset(first),
                canonicalizer.canonicalDataset(second));
    }

    @Test
    void changingSeedChangesDataset() {
        BehaviorGeneratedDataset first = generator.generate(scenario(1001, false));
        BehaviorGeneratedDataset second = generator.generate(scenario(2002, false));

        assertNotEquals(
                canonicalizer.semanticDigest(first),
                canonicalizer.semanticDigest(second));
    }

    @Test
    void twentyFourHourDatasetHasStableWindowsAndEpisodeBoundaries() {
        BehaviorGeneratedDataset dataset = generator.generate(scenario(1001, true));

        assertEquals(288, dataset.windows().size());
        assertEquals(288, dataset.manifest().expectedWindowCount());
        assertTrue(dataset.windows().stream()
                .anyMatch(window -> window.inputQuality() == InputQuality.UNKNOWN));
        assertTrue(dataset.episodes().size() > 1);

        Map<?, List<BehaviorGeneratedWindow>> byEpisode = dataset.windows().stream()
                .collect(Collectors.groupingBy(BehaviorGeneratedWindow::episodeId));
        byEpisode.forEach((episodeId, windows) -> {
            assertEquals(1, windows.stream().map(BehaviorGeneratedWindow::dominantBehavior).distinct().count());
            for (int i = 1; i < windows.size(); i++) {
                assertEquals(windows.get(i - 1).endAt(), windows.get(i).startAt());
            }
        });
        assertEquals(byEpisode.keySet().size(), dataset.episodes().size());
    }

    @Test
    void canonicalScenarioIsDeterministic() {
        assertEquals(
                canonicalizer.scenarioDigest(scenario(1001, false)),
                canonicalizer.scenarioDigest(scenario(1001, false)));
        assertNotEquals(
                canonicalizer.scenarioDigest(scenario(1001, false)),
                canonicalizer.scenarioDigest(scenario(2002, false)));
    }

    private BehaviorScenarioDefinition scenario(long seed, boolean withMissing) {
        return new BehaviorScenarioDefinition(
                "behavior-smoke",
                seed,
                "behavior-generator-v1",
                Instant.parse("2026-08-23T00:00:00Z"),
                Instant.parse("2026-08-24T00:00:00Z"),
                List.of(new BehaviorSubject(1L, 1L, 1L, 5L, 8, -4, 3.2)),
                BehaviorTransitionMatrix.defaultMatrix(),
                List.of(4.0, 3.0, 2.0, 1.0, 0.2),
                new BehaviorRealismProfile(
                        0.003,
                        0.01,
                        withMissing ? 0.03 : 0.0,
                        0.01));
    }
}
