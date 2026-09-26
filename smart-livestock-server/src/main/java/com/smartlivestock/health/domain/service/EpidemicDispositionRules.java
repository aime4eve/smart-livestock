package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.model.EpidemicDispositionAction;
import com.smartlivestock.health.domain.model.EpidemicDispositionTier;

/**
 * Pure business rules for epidemic disposition importance. Aggregation gathers
 * evidence; this class is the only place allowed to assign operational urgency.
 */
public final class EpidemicDispositionRules {

    private EpidemicDispositionRules() {}

    public static Result classify(boolean directSource,
                                  int directAgeHours,
                                  int maxRiskScore,
                                  int shortestDepth,
                                  boolean healthSignal,
                                  int criticalRisk,
                                  int criticalNoHealthRisk,
                                  int observationRisk) {
        if (directSource && directAgeHours <= 24 && maxRiskScore >= criticalRisk && healthSignal) {
            return new Result(
                    EpidemicDispositionTier.CRITICAL, EpidemicDispositionAction.ISOLATE_NOTIFY_VET, 2);
        }
        if (directSource && directAgeHours <= 24 && maxRiskScore >= criticalNoHealthRisk) {
            return new Result(
                    EpidemicDispositionTier.CRITICAL, EpidemicDispositionAction.IMMEDIATE_VET_CHECK, 4);
        }
        if ((directSource && directAgeHours <= 48 && maxRiskScore >= observationRisk)
                || (shortestDepth <= 2 && maxRiskScore >= criticalRisk)) {
            return new Result(
                    EpidemicDispositionTier.OBSERVATION, EpidemicDispositionAction.HEALTH_RECHECK, 24);
        }
        if (maxRiskScore >= observationRisk) {
            return new Result(
                    EpidemicDispositionTier.TRACKING, EpidemicDispositionAction.CONTINUE_TRACING, 72);
        }
        return new Result(EpidemicDispositionTier.ARCHIVE, EpidemicDispositionAction.ARCHIVE_ONLY, null);
    }

    public record Result(
            EpidemicDispositionTier tier,
            EpidemicDispositionAction action,
            Integer dueHours
    ) {}
}
