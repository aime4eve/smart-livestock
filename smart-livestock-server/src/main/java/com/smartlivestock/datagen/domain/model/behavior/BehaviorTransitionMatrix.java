package com.smartlivestock.datagen.domain.model.behavior;

import java.util.EnumMap;
import java.util.Map;
import java.util.Random;

public final class BehaviorTransitionMatrix {
    private final Map<BehaviorDominant, Map<BehaviorDominant, Double>> weights =
            new EnumMap<>(BehaviorDominant.class);

    public BehaviorTransitionMatrix(
            Map<BehaviorDominant, Map<BehaviorDominant, Double>> weights) {
        for (BehaviorDominant from : BehaviorDominant.values()) {
            Map<BehaviorDominant, Double> row = weights.get(from);
            if (row == null) {
                throw new IllegalArgumentException("Missing transition row: " + from);
            }
            Map<BehaviorDominant, Double> copied = new EnumMap<>(BehaviorDominant.class);
            double sum = 0;
            for (BehaviorDominant to : BehaviorDominant.values()) {
                Double weight = row.get(to);
                if (weight == null || !Double.isFinite(weight) || weight < 0) {
                    throw new IllegalArgumentException("Invalid transition weight: " + from + " -> " + to);
                }
                copied.put(to, weight);
                sum += weight;
            }
            if (sum <= 0) {
                throw new IllegalArgumentException("Transition row must have positive weight: " + from);
            }
            this.weights.put(from, copied);
        }
    }

    public static BehaviorTransitionMatrix defaultMatrix() {
        Map<BehaviorDominant, Map<BehaviorDominant, Double>> weights =
                new EnumMap<>(BehaviorDominant.class);
        for (BehaviorDominant from : BehaviorDominant.values()) {
            Map<BehaviorDominant, Double> row = new EnumMap<>(BehaviorDominant.class);
            for (BehaviorDominant to : BehaviorDominant.values()) {
                row.put(to, from == to ? 7.0 : defaultWeight(to));
            }
            weights.put(from, row);
        }
        return new BehaviorTransitionMatrix(weights);
    }

    public Map<BehaviorDominant, Map<BehaviorDominant, Double>> weights() {
        Map<BehaviorDominant, Map<BehaviorDominant, Double>> copy =
                new EnumMap<>(BehaviorDominant.class);
        weights.forEach((key, value) -> copy.put(key, new EnumMap<>(value)));
        return copy;
    }

    public BehaviorDominant next(BehaviorDominant current, Random random) {
        double selector = random.nextDouble();
        double cumulative = 0;
        Map<BehaviorDominant, Double> row = weights.get(current);
        double total = row.values().stream().mapToDouble(Double::doubleValue).sum();
        for (BehaviorDominant candidate : BehaviorDominant.values()) {
            cumulative += row.get(candidate) / total;
            if (selector < cumulative) {
                return candidate;
            }
        }
        return BehaviorDominant.OTHER;
    }

    private static double defaultWeight(BehaviorDominant dominant) {
        return switch (dominant) {
            case LYING -> 3.0;
            case RUMINATING, FEEDING -> 2.0;
            case WALKING -> 1.0;
            case OTHER -> 0.5;
        };
    }
}
