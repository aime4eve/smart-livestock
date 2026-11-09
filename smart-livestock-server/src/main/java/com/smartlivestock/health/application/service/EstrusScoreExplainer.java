package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.EstrusScore;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import com.smartlivestock.health.domain.service.EstrusAnalysisService.ComponentBreakdown;
import com.smartlivestock.health.infrastructure.config.EstrusScoringProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Recomputes the component breakdown of a stored {@code estrus_scores} row for
 * UI explanation (NIX-390 Task 1). Pure calculation over the row's persisted
 * feature columns — no re-read of telemetry, no DB access — dispatched on the
 * row's {@code featureVersion}:
 *
 * <ul>
 *   <li>{@code LEGACY}: components via the legacy short-window curves with the
 *       fixed 0.4/0.3/0.3 weights (a null input scores 0 but keeps its weight,
 *       mirroring {@code calculateScore}).</li>
 *   <li>{@code NORMALIZED-V2}: components via the ladders from
 *       {@link EstrusScoringProperties} with the participating-weight
 *       normalization (each weight divided by the participating sum, mirroring
 *       {@code calculateScoreNormalized}); the temperature component reuses the
 *       legacy curve floored at 0.</li>
 * </ul>
 *
 * <p>Any other / null {@code featureVersion} returns {@code null}: the row
 * predates provenance stamping and cannot be explained reliably.</p>
 */
@Service
@RequiredArgsConstructor
public class EstrusScoreExplainer {

    public static final String FEATURE_VERSION_LEGACY = "LEGACY";
    public static final String FEATURE_VERSION_NORMALIZED_V2 = "NORMALIZED-V2";

    private final EstrusAnalysisService estrusAnalysisService;
    private final EstrusScoringProperties estrusScoringProperties;

    /**
     * Explanation payload for one estrus_scores row.
     *
     * @param breakdown              per-component scores and effective weights
     * @param activityRatio          display-only current/baseline activity
     *                               ratio ({@code 1 + stepIncreasePercent/100});
     *                               null on LEGACY rows (the legacy step column
     *                               is a short-window increase percent, not a
     *                               level ratio)
     * @param distanceRatio          persisted distance level ratio, or null
     * @param distanceParticipated   whether the distance component actually fed
     *                               the weighted sum
     * @param temperatureParticipated whether the temperature component fed the
     *                               weighted sum
     */
    public record EstrusScoreExplanation(
            ComponentBreakdown breakdown,
            BigDecimal activityRatio,
            BigDecimal distanceRatio,
            boolean distanceParticipated,
            boolean temperatureParticipated) {
    }

    /**
     * Explains one stored row, or returns {@code null} when the row's
     * {@code featureVersion} is missing/unknown.
     */
    public EstrusScoreExplanation explain(EstrusScore row) {
        if (row == null || row.getFeatureVersion() == null) {
            return null;
        }
        switch (row.getFeatureVersion()) {
            case FEATURE_VERSION_LEGACY: {
                ComponentBreakdown breakdown = estrusAnalysisService.legacyBreakdown(
                        row.getStepIncreasePercent(), row.getTempDelta(), row.getDistanceDelta());
                // LEGACY rows carry no level ratios; participation follows the
                // persisted columns (a null column means the channel was absent).
                return new EstrusScoreExplanation(breakdown, null, null,
                        row.getDistanceDelta() != null, row.getTempDelta() != null);
            }
            case FEATURE_VERSION_NORMALIZED_V2: {
                ComponentBreakdown breakdown = estrusAnalysisService.normalizedBreakdown(
                        row.getStepIncreasePercent(), row.getTempDelta(), row.getDistanceRatio(),
                        estrusScoringProperties.toActivityLadder(),
                        estrusScoringProperties.toDistanceLadder());
                // Display ratio reconstructed from the increase-percent column;
                // null stepIncreasePercent cannot occur on NORMALIZED rows (the
                // path always writes it), but degrades gracefully if it does.
                BigDecimal activityRatio = row.getStepIncreasePercent() == null ? null
                        : BigDecimal.valueOf(100L + row.getStepIncreasePercent())
                                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                return new EstrusScoreExplanation(breakdown, activityRatio, row.getDistanceRatio(),
                        row.getDistanceRatio() != null, row.getTempDelta() != null);
            }
            default:
                return null;
        }
    }
}
