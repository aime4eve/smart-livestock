package com.smartlivestock.health.infrastructure.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

/**
 * Tunables for the cross-event-window estrus scoring normalization (NIX-380).
 * The normalized kernel compares the current activity / distance level against
 * same-phase baselines taken 24h-apart windows before the current window,
 * replacing the legacy "recent-3 vs rest-4" short-window ratio that
 * under-detects gradual ~18h estrus episodes at 30-minute telemetry
 * granularity.
 *
 * <p>{@code mode} selects the scoring path consumed from the Task 2 wiring
 * onward: NORMALIZED (default) uses the cross-event-window kernel, LEGACY
 * keeps the historical short-window formula. Task 1 only defines and
 * validates the fields; consumption is wired later.</p>
 */
@Component
@ConfigurationProperties(prefix = "smartlivestock.estrus-scoring")
@Getter
@Setter
public class EstrusScoringProperties {

    /** Scoring path selector: NORMALIZED (cross-event-window kernel) or LEGACY (short-window formula). */
    private String mode = "NORMALIZED";
    /** Current comparison window length in hours (event-time based). */
    private long currentWindowHours = 6;
    /** Number of same-phase baseline windows preceding the current window (fetched at 24h multiples back). */
    private int baselineWindowCount = 3;
    /** Gap in hours between the current window and the first baseline window; must be a positive multiple of 24 to align wall-clock phase. */
    private long baselineWindowOffsetHours = 24;
    /** Qualified activity samples required inside the current window. */
    private int minCurrentActivitySamples = 4;
    /** Qualified activity samples required per baseline window for it to count. */
    private int minBaselineActivitySamples = 4;
    /** Qualified temperature samples required for the temperature component. */
    private int minTemperatureSamples = 2;
    /** Max rows a single window SQL read may return (read clamp; consumed by Task 2). */
    private int maxWindowRows = 600;

    /** Activity ratio rung for the very-high score. */
    private double activityRatioVeryHigh = 3.0;
    /** Activity score at/above the very-high rung. */
    private int activityScoreVeryHigh = 100;
    /** Activity ratio rung for the high score. */
    private double activityRatioHigh = 2.0;
    /** Activity score at/above the high rung. */
    private int activityScoreHigh = 95;
    /** Activity ratio rung for the mid score (linear band lower anchor sits at ratio 1.0). */
    private double activityRatioMid = 1.5;
    /** Activity score at/above the mid rung. */
    private int activityScoreMid = 45;

    /** Distance ratio rung for the very-high score. */
    private double distanceRatioVeryHigh = 3.0;
    /** Distance score at/above the very-high rung. */
    private int distanceScoreVeryHigh = 100;
    /** Distance ratio rung for the high score. */
    private double distanceRatioHigh = 2.0;
    /** Distance score at/above the high rung. */
    private int distanceScoreHigh = 95;
    /** Distance ratio rung for the mid score (linear band lower anchor sits at ratio 1.0). */
    private double distanceRatioMid = 1.5;
    /** Distance score at/above the mid rung. */
    private int distanceScoreMid = 45;

    @PostConstruct
    void validate() {
        if (!"NORMALIZED".equals(mode) && !"LEGACY".equals(mode)) {
            throw new IllegalStateException(
                    "smartlivestock.estrus-scoring.mode must be NORMALIZED or LEGACY, got "
                            + mode);
        }
        if (baselineWindowCount < 1) {
            throw new IllegalStateException(
                    "smartlivestock.estrus-scoring.baseline-window-count must be >= 1, got "
                            + baselineWindowCount);
        }
        if (baselineWindowOffsetHours <= 0 || baselineWindowOffsetHours % 24 != 0) {
            throw new IllegalStateException(
                    "smartlivestock.estrus-scoring.baseline-window-offset-hours must be a positive multiple of 24, got "
                            + baselineWindowOffsetHours);
        }
        validateLadder("activity", activityRatioVeryHigh, activityRatioHigh, activityRatioMid);
        validateLadder("distance", distanceRatioVeryHigh, distanceRatioHigh, distanceRatioMid);
    }

    private static void validateLadder(String feature, double veryHigh, double high, double mid) {
        if (!(veryHigh > high && high > mid && mid > 1.0)) {
            throw new IllegalStateException(
                    "smartlivestock.estrus-scoring." + feature
                            + " ladder rungs must satisfy ratioVeryHigh > ratioHigh > ratioMid > 1.0, got "
                            + veryHigh + "/" + high + "/" + mid);
        }
    }
}
