package com.smartlivestock.datagen.domain.model.behavior;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

public record BehaviorScenarioDefinition(
        String scenarioId,
        long seed,
        String generatorVersion,
        Instant startAt,
        Instant endAt,
        List<BehaviorSubject> subjects,
        BehaviorTransitionMatrix transitionMatrix,
        List<Double> initialWeights,
        BehaviorRealismProfile realismProfile) {
    public static final Duration MAX_DURATION = Duration.ofDays(31);

    public BehaviorScenarioDefinition {
        if (scenarioId == null || scenarioId.isBlank()
                || generatorVersion == null || generatorVersion.isBlank()
                || startAt == null || endAt == null || subjects == null || subjects.isEmpty()
                || transitionMatrix == null || realismProfile == null) {
            throw new IllegalArgumentException("Behavior scenario definition is incomplete");
        }
        if (startAt.getEpochSecond() % 300 != 0
                || endAt.getEpochSecond() % 300 != 0
                || !endAt.isAfter(startAt)
                || Duration.between(startAt, endAt).compareTo(MAX_DURATION) > 0) {
            throw new IllegalArgumentException("Behavior scenario window must align to 5 minutes and be at most 31 days");
        }
        List<BehaviorSubject> sorted = new ArrayList<>(subjects);
        sorted.sort(Comparator
                .comparing(BehaviorSubject::deviceId, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(BehaviorSubject::livestockId, Comparator.nullsLast(Comparator.naturalOrder())));
        for (int i = 1; i < sorted.size(); i++) {
            if (Objects.equals(sorted.get(i - 1).deviceId(), sorted.get(i).deviceId())) {
                throw new IllegalArgumentException("Behavior subjects must have unique devices");
            }
        }
        if (initialWeights == null || initialWeights.size() != BehaviorDominant.values().length) {
            throw new IllegalArgumentException("Behavior initial weights must cover every dominant class");
        }
        double sum = 0;
        for (double weight : initialWeights) {
            if (!Double.isFinite(weight) || weight < 0) {
                throw new IllegalArgumentException("Behavior initial weights are invalid");
            }
            sum += weight;
        }
        if (sum <= 0) {
            throw new IllegalArgumentException("Behavior initial weights must have positive weight");
        }
        subjects = List.copyOf(sorted);
        initialWeights = List.copyOf(initialWeights);
    }

    public int expectedWindows() {
        return (int) (Duration.between(startAt, endAt).toSeconds() / 300);
    }
}
