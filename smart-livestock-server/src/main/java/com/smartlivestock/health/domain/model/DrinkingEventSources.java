package com.smartlivestock.health.domain.model;

/**
 * Source values of {@code drinking_events.source}. The column is deliberately
 * a plain VARCHAR without a CHECK: detected rows pass through the source of
 * the temperature point they were derived from (DATAGEN / THINGSBOARD /
 * AGENTIC_PLATFORM / MANUAL_IMPORT / …, user ruling 2026-10-05 — simulation
 * events stay usable for demos while remaining distinguishable by source).
 * Only the two values that never come from a temperature point are
 * constants here.
 */
public final class DrinkingEventSources {

    /** Ranch-owner back-filled missed event (spec §15.2 manual channel). */
    public static final String MANUAL = "MANUAL";

    /** Borderline valley auto-discovered by the detector (spec §15.2). */
    public static final String ALGORITHM_CANDIDATE = "ALGORITHM_CANDIDATE";

    private DrinkingEventSources() {}
}
