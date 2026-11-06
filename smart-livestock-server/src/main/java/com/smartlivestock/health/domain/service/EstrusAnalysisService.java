package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

/**
 * Multi-dimensional estrus scoring (0-100).
 * score = step_score × 0.4 + temp_score × 0.3 + distance_score × 0.3
 */
@Service
public class EstrusAnalysisService {

    public int calculateScore(int stepIncreasePercent, BigDecimal tempDelta, BigDecimal distanceDelta) {
        double stepScore = scoreStepIncrease(stepIncreasePercent);
        double tempScore = scoreTempDelta(tempDelta);
        double distScore = scoreDistanceDelta(distanceDelta);
       double raw = stepScore * 0.4 + tempScore * 0.3 + distScore * 0.3;
       return (int) Math.round(Math.max(0, Math.min(100, raw)));
    }

   public String generateAdvice(int score) {
       if (score >= 70) {
            return "High estrus score. Breeding recommended within 12 hours.";
       } else if (score >= 50) {
            return "Moderately high estrus score. Continue monitoring and prepare for breeding.";
       }
        return "Not in estrus";
   }

    private double scoreStepIncrease(int increasePercent) {
        if (increasePercent > 300) return 85 + Math.min((increasePercent - 300) / 100.0 * 15, 15);
        if (increasePercent > 150) return 60 + (increasePercent - 150) / 150.0 * 25;
        if (increasePercent > 50) return 20 + (increasePercent - 50) / 100.0 * 40;
        return increasePercent / 50.0 * 20;
    }

    private double scoreTempDelta(BigDecimal delta) {
        if (delta == null) return 0;
        double d = delta.doubleValue();
        if (d > 0.5) return 40 + Math.min((d - 0.5) / 0.5 * 20, 20);
        if (d > 0.2) return 10 + (d - 0.2) / 0.3 * 30;
        return d / 0.2 * 10;
    }

    private double scoreDistanceDelta(BigDecimal delta) {
        if (delta == null) return 0;
        double d = delta.doubleValue();
        if (d > 2000) return 50 + Math.min((d - 2000) / 1000.0 * 20, 20);
        if (d > 500) return 15 + (d - 500) / 1500.0 * 35;
        return d / 500.0 * 15;
    }

    // ---------------------------------------------------------------------------
    // Normalized scoring kernel (NIX-380 Task 1). The legacy formula above is
    // intentionally untouched; the Task 2 wiring selects between the two paths.
    // ---------------------------------------------------------------------------

    /**
     * Threshold/score ladder for one normalized feature (activity or distance).
     * Rungs are absolute level ratios: current-window level divided by the level
     * of same-phase baseline windows taken 24h apart. Shape: {@code ratio >=
     * ratioVeryHigh} scores {@code scoreVeryHigh}; {@code ratio >= ratioHigh}
     * scores {@code scoreHigh}; {@code ratio >= ratioMid} scores {@code scoreMid};
     * within {@code [1.0, ratioMid)} the score interpolates linearly from 0 up to
     * {@code scoreMid}; below 1.0 the feature scores 0 (no rise against baseline).
     *
     * <p>Instances are built by callers from {@code EstrusScoringProperties}; the
     * domain kernel stays a pure function of the ladder handed in.</p>
     */
    public record EstrusFeatureLadder(
            double ratioVeryHigh, int scoreVeryHigh,
            double ratioHigh, int scoreHigh,
            double ratioMid, int scoreMid) {
    }

    /**
     * Default ladder mirroring the {@code smartlivestock.estrus-scoring} defaults
     * (3.0/100, 2.0/100, 1.5/45). Serves unit tests and callers without an
     * explicit ladder.
     */
    public static final EstrusFeatureLadder DEFAULT_LADDER =
            new EstrusFeatureLadder(3.0, 100, 2.0, 100, 1.5, 45);

    /**
     * Normalized estrus scoring across event-time windows (NIX-380).
     *
     * <p>Motivation: the legacy component scores are short-window relative ratios
     * ("recent 3 samples vs the other 4") evaluated inside a single event. At
     * 30-minute telemetry granularity a gradual ~18h estrus episode never clears
     * that relative bar, so whole episodes go undetected (simulation:
     * episodes = 0). This kernel compares absolute levels instead: the activity
     * and distance arguments are current-window vs same-phase-baseline ratios
     * (24h-apart windows), so a slow but sustained rise still scores high.</p>
     *
     * <p>Component scores: activity and distance via
     * {@link #ladderScore(double, EstrusFeatureLadder)} with ladders supplied by
     * the caller (built from {@code EstrusScoringProperties}); temperature reuses
     * the legacy {@code scoreTempDelta} curve floored at zero for negative
     * deltas (see the inline comment below). A null argument means "component
     * unavailable" — it contributes no score and its weight is dropped from the
     * denominator, so CAPSULE-only animals (activity + temperature) are scored on
     * their available components instead of being diluted by zeros. When all
     * three components are unavailable the method returns 0; callers guard that
     * case (Task 2), the kernel only guarantees it does not blow up.</p>
     *
     * @param activityRatio  current/baseline activity level ratio, null if unavailable
     * @param tempDelta      temperature delta in °C, null if unavailable
     * @param distanceRatio  current/baseline distance level ratio, null if unavailable
     * @param activityLadder activity ladder; falls back to {@link #DEFAULT_LADDER} when null
     * @param distanceLadder distance ladder; falls back to {@link #DEFAULT_LADDER} when null
     * @return weighted score 0-100, rounded; weights 0.4 / 0.3 / 0.3 over the
     *         available components only (same weights as {@link #calculateScore})
     */
    public int calculateScoreNormalized(BigDecimal activityRatio, BigDecimal tempDelta, BigDecimal distanceRatio,
                                        EstrusFeatureLadder activityLadder, EstrusFeatureLadder distanceLadder) {
        EstrusFeatureLadder actLadder = activityLadder == null ? DEFAULT_LADDER : activityLadder;
        EstrusFeatureLadder distLadder = distanceLadder == null ? DEFAULT_LADDER : distanceLadder;

        double weightedSum = 0;
        double weightSum = 0;
        if (activityRatio != null) {
            weightedSum += ladderScore(activityRatio.doubleValue(), actLadder) * 0.4;
            weightSum += 0.4;
        }
        if (tempDelta != null) {
            // Floored at 0 for negative deltas (NIX-380 simulation forensics):
            // the legacy curve returns d/0.2×10 unbounded below, and at
            // 30-minute granularity most positions carry a drinking-valley
            // tempDelta of −2…−14 °C — a cow being COOLER than her baseline
            // (drinking bout, diurnal trough, noise) is not evidence against
            // estrus, so absence of a temperature rise contributes 0 instead
            // of dragging the whole score down. Positive deltas still score
            // normally (up to +60). The legacy calculateScore keeps its
            // original curve untouched.
            weightedSum += Math.max(0, scoreTempDelta(tempDelta)) * 0.3;
            weightSum += 0.3;
        }
        if (distanceRatio != null) {
            weightedSum += ladderScore(distanceRatio.doubleValue(), distLadder) * 0.3;
            weightSum += 0.3;
        }
        if (weightSum == 0) {
            return 0;
        }
        return (int) Math.round(Math.max(0, Math.min(100, weightedSum / weightSum)));
    }

    /**
     * Maps an absolute level ratio onto the ladder. Same shape for activity and
     * distance: the top rung saturates at {@code scoreVeryHigh}, lower rungs step
     * at {@code ratioHigh} / {@code ratioMid}, and the {@code [1.0, ratioMid)}
     * band interpolates linearly from 0 to {@code scoreMid} so a ratio of exactly
     * 1.0 (no change vs baseline) contributes nothing.
     *
     * <p>Package-private for boundary tests; the ratio must be non-null (the
     * availability check lives in {@link #calculateScoreNormalized}).</p>
     */
    static double ladderScore(double ratio, EstrusFeatureLadder ladder) {
        if (ratio >= ladder.ratioVeryHigh()) return ladder.scoreVeryHigh();
        if (ratio >= ladder.ratioHigh()) return ladder.scoreHigh();
        if (ratio >= ladder.ratioMid()) return ladder.scoreMid();
        if (ratio >= 1.0) return ladder.scoreMid() * (ratio - 1.0) / (ladder.ratioMid() - 1.0);
        return 0;
    }
}
