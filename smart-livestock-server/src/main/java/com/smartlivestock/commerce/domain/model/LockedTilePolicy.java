package com.smartlivestock.commerce.domain.model;

/**
 * Presentation policy for subscription-locked health tiles (NIX-389).
 * Platform-level single setting persisted in platform_display_settings
 * (V20261107100000).
 */
public enum LockedTilePolicy {

    /** Locked tiles stay visible with a lock affordance (pre-change behaviour). */
    SHOW_LOCKED,

    /** Locked tiles are dropped from what the client renders. */
    HIDE;

    /**
     * Parse a persisted/raw value; unknown or blank input falls back to
     * {@link #SHOW_LOCKED} so a data drift can never hide tiles by accident.
     */
    public static LockedTilePolicy fromString(String value) {
        if (value == null || value.isBlank()) {
            return SHOW_LOCKED;
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return SHOW_LOCKED;
        }
    }
}
