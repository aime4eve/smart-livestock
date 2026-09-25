package com.smartlivestock.health.application.service;

/**
 * AI observation bands and plain-language finding codes (NIX-245 spec §6).
 * The backend emits codes only; the frontend maps them to localized labels
 * so no technical wording (score%, model name, n_eff) reaches the UI.
 */
public final class AiHealthBands {

    private AiHealthBands() {}

    /** calm < 0.3, watch 0.3–0.7, alarm >= 0.7 (alarm auto-raises a ticket). */
    public static String band(double score) {
        if (score >= 0.7) return "alarm";
        if (score >= 0.3) return "watch";
        return "calm";
    }

    /** Finding codes the frontend translates ("体温突然升高" etc.). */
    public static String findingCode(String anomalyType) {
        if (anomalyType == null) return "none";
        return switch (anomalyType) {
            case "abrupt_change" -> "temp_spike";
            case "circadian_disruption" -> "rhythm_off";
            case "multivariate" -> "multi_shift";
            default -> "none";
        };
    }
}
