package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import org.springframework.lang.Nullable;

/**
 * NIX-198: single source for the derived livestock health status, shared by
 * the ranch-overview markers, the livestock detail page and every list
 * surface. The {@code health_status} column is a registration default with
 * no business writer (deprecated since NIX-256) — consuming it directly made
 * the detail page report HEALTHY forever while the map derived real states
 * from the same health snapshots.
 */
public final class HealthStatusDeriver {

    /** NIX-381 calving linkage: alert band lower bound. */
    public static final int CALVING_WARNING_SCORE = 70;

    private HealthStatusDeriver() {
    }

    /**
     * "NORMAL" / "WARNING" / "CRITICAL" — the overview marker vocabulary.
     * A null snapshot (no health data yet) is never alarming.
     */
    public static String deriveHealthStatus(
            @Nullable HealthQueryPort.LivestockHealthState health) {
        if (health == null) return "NORMAL";
        if ("CRITICAL".equals(health.tempStatus())) return "CRITICAL";
        if ("FEVER".equals(health.tempStatus())) return "WARNING";
        if ("ABNORMAL".equals(health.motilityStatus())) return "WARNING";
        if ("ELEVATED".equals(health.tempStatus())) return "WARNING";
        if (health.estrusScore() >= 70) return "WARNING";
        // NIX-381 map linkage: null = never scored / released, never alarming.
        if (health.calvingRiskScore() != null
                && health.calvingRiskScore() >= CALVING_WARNING_SCORE) {
            return "WARNING";
        }
        return "NORMAL";
    }

    /** Primary driver for the marker tooltip; "" when nothing demands attention. */
    public static String derivePrimaryAlert(
            @Nullable HealthQueryPort.LivestockHealthState health) {
        if (health == null) return "";
        if ("CRITICAL".equals(health.tempStatus())
                || "FEVER".equals(health.tempStatus())) return "FEVER";
        if ("ABNORMAL".equals(health.motilityStatus())) return "DIGESTIVE";
        if (health.estrusScore() >= 70) return "ESTRUS";
        if (health.calvingRiskScore() != null
                && health.calvingRiskScore() >= CALVING_WARNING_SCORE) {
            return "CALVING";
        }
        return "";
    }
}
