package com.smartlivestock.health.domain.model;

/**
 * Human verdict on a drinking event row (NIX-256 marking loop, spec §15.1).
 * CONFIRMED/REJECTED labels survive recalculations (§15.4): the recalc
 * snapshots them and restores the label onto any re-detected row with the
 * same start; MANUAL rows are never deleted at all.
 */
public enum DrinkingEventLabel {
    UNLABELED,
    CONFIRMED,
    REJECTED
}
