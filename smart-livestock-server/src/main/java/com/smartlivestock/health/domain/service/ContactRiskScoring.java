package com.smartlivestock.health.domain.service;

import java.math.BigDecimal;

/**
 * Pure contact risk scoring — the exact three-part scale used by
 * {@code HealthApplicationService#getContactNetwork} (V31 seed scale:
 * 82/HIGH, 58/MEDIUM, 28/LOW). Extracted as the shared kernel so the
 * contact analyzer (scheduler track + mark-diseased snapshot track) and
 * the contact network view score identically.
 */
public final class ContactRiskScoring {

    private ContactRiskScoring() {}

    public static int timeScore(long hoursAgo) {
        if (hoursAgo <= 24) return 40;
        if (hoursAgo <= 48) return 25;
        return 12;
    }

    public static int distanceScore(BigDecimal proximityMeters) {
        if (proximityMeters == null) return 5;
        double dist = proximityMeters.doubleValue();
        if (dist < 5) return 35;
        if (dist < 15) return 25;
        if (dist < 30) return 15;
        return 5;
    }

    public static int durationScore(Integer durationMinutes) {
        if (durationMinutes == null) return 3;
        if (durationMinutes > 30) return 25;
        if (durationMinutes > 15) return 18;
        if (durationMinutes > 5) return 10;
        return 3;
    }

    public static int totalScore(long hoursAgo, BigDecimal proximityMeters,
                                 Integer durationMinutes) {
        return timeScore(hoursAgo)
                + distanceScore(proximityMeters)
                + durationScore(durationMinutes);
    }

    public static String riskLevel(int totalScore) {
        if (totalScore >= 70) return "HIGH";
        if (totalScore >= 40) return "MEDIUM";
        return "LOW";
    }
}
