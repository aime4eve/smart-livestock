package com.smartlivestock.health.domain.service;

/**
 * Why a temperature sample was not admitted into the individual baseline
 * learning window (plan 2026-11-03 Task 2).
 *
 * <p>Constant order mirrors the admission pipeline stages; for a given
 * sample the first matching reason wins (exactly one entry per rejected
 * sample in {@link BaselineLearningResult.ExcludedSample}).</p>
 */
public enum BaselineAdmissionReason {
    /** Telemetry source is not on the learning whitelist (e.g. DATAGEN, UNKNOWN). */
    SOURCE_NOT_ALLOWED,
    /** Reading outside the physiologically plausible range 35.0-43.0 °C. */
    IMPLAUSIBLE,
    /** Redundant frame: same (deviceId, recordedAt, source) already admitted. */
    DUPLICATE,
    /** Sample falls inside a manual ILLNESS/RECOVERY window (plus fever buffer). */
    ILLNESS_WINDOW,
    /** Sample falls inside an active fever alert window (only when previous baseline is LEARNED). */
    FEVER_ALERT_WINDOW,
    /** LEARNED re-learning: sample itself reads ≥1.0°C over the frozen pre-learning baseline. */
    FEVER_ELEVATED,
    /** Sample falls inside a drinking event interval plus its recovery window. */
    DRINKING_WINDOW,
    /** Sample matched a nearby activity frame at/above the individual's activity median. */
    ACTIVE_PERIOD,
    /** Sample could not be joined to any activity frame and is not a night sample. */
    ACTIVITY_UNKNOWN,
    /** Sample deviates more than 3x the effective MAD from the window median. */
    ROBUST_OUTLIER
}
