package com.smartlivestock.health.infrastructure.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

import java.math.BigDecimal;
import java.util.List;

/**
 * Tunables for the individual temperature baseline learning pipeline
 * (plan 2026-11-03). Two independent switches: {@code enabled} gates the
 * learning scheduler, {@code applyLearned} gates consumption of learned
 * baselines — turning both off rolls the system back to DEFAULT behavior
 * while keeping learned fields/audit intact.
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.health.baseline-learning")
@Getter
@Setter
public class BaselineLearningProperties {

    /** Master switch for the baseline learning scheduler. */
    private boolean enabled = true;
    /** Whether consumers (estrus scoring / temp delta) use LEARNED baselines. */
    private boolean applyLearned = true;
    /** Event-time sliding window length in days (recorded_at based). */
    private int windowDays = 10;
    /** Qualified days required before DEFAULT can flip to LEARNED. */
    private int minQualifiedDays = 7;
    /** Admitted samples required per day for that day to qualify. */
    private int minSamplesPerDay = 2;
    /** Minimum band half-width (°C) used when MAD = 0 so all samples survive. */
    private BigDecimal madFloor = new BigDecimal("0.05");
    /** Fever exclusion buffer in hours after a fever/illness window ends. */
    private int feverBufferHours = 6;
    /** Post-drinking recovery window in minutes excluded from admission. */
    private int drinkingRecoveryWindowMin = 120;
    /** ± tolerance in minutes when joining temperature frames to activity records. */
    private int activityToleranceMin = 15;
    /** Scheduler poll interval in milliseconds. */
    private long pollMs = 900_000;
    /** Max livestock recalculated per scheduler poll. */
    private int maxPerPoll = 200;
    /** Per-livestock recalc throttle in minutes (manual recalc bypasses it). */
    private int minRecalcIntervalMinutes = 30;
    /** Telemetry sources eligible for learning; DATAGEN/UNKNOWN never qualify. */
    private List<String> allowedSources =
            List.of("AGENTIC_PLATFORM", "THINGSBOARD", "HTTP", "MANUAL_IMPORT");
    /** Algorithm version stamped on learned baselines and estrus audit rows. */
    private String baselineAlgorithmVersion = "V1";

    @PostConstruct
    void validate() {
        if (windowDays < 7 || windowDays > 14) {
            throw new IllegalStateException(
                    "smartlivestock.health.baseline-learning.window-days must be within 7-14, got "
                            + windowDays);
        }
        if (minQualifiedDays < 1) {
            throw new IllegalStateException(
                    "smartlivestock.health.baseline-learning.min-qualified-days must be >= 1, got "
                            + minQualifiedDays);
        }
        if (minSamplesPerDay < 1) {
            throw new IllegalStateException(
                    "smartlivestock.health.baseline-learning.min-samples-per-day must be >= 1, got "
                            + minSamplesPerDay);
        }
        if (allowedSources == null || allowedSources.isEmpty()) {
            throw new IllegalStateException(
                    "smartlivestock.health.baseline-learning.allowed-sources must not be empty");
        }
    }
}
