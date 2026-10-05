package com.smartlivestock.health.domain.model;

/**
 * {@code drinking_events.algorithm_version} values. Detection rows share
 * {@link #V1} so a recalc deletes-and-reinserts them under the same UNIQUE
 * key; manual rows use {@link #MANUAL} so they never collide with algorithm
 * rows at the same start instant.
 */
public final class DrinkingAlgorithmVersion {

    /** Heuristic v1 detector (two criteria + recovery + merge, spec §14 params). */
    public static final String V1 = "v1";

    /** Rows created via POST /manual (marking loop, spec §15.2). */
    public static final String MANUAL = "manual";

    private DrinkingAlgorithmVersion() {}
}
