package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Read-only feature-gate lookups keyed by an already-resolved tier string,
 * for consumers that resolve the tier outside HealthSubscriptionPort (e.g.
 * the Open API telemetry endpoints, which take the tier from the
 * TenantSubscriptionResolver request context — NIX-323).
 *
 * Defaults mirror HealthSubscriptionPortImpl: unknown gate → disabled
 * feature / 7-day retention, so a missing seed row never widens access.
 */
@Service
@RequiredArgsConstructor
public class FeatureGateQueryService {

    private static final int DEFAULT_RETENTION_DAYS = 7;

    private final FeatureGateRepository featureGateRepository;

    public record GateConfig(boolean enabled, Integer limitValue, int retentionDays) {}

    public GateConfig getGate(String tier, String featureKey) {
        return featureGateRepository.findByTierAndFeatureKey(tier, featureKey)
                .map(gate -> new GateConfig(
                        gate.isEnabled() && isNotLocked(gate),
                        gate.getLimitValue(),
                        retentionOrDefault(gate)))
                .orElse(new GateConfig(false, null, DEFAULT_RETENTION_DAYS));
    }

    public int getRetentionDays(String tier, String featureKey) {
        return getGate(tier, featureKey).retentionDays();
    }

    private static boolean isNotLocked(FeatureGate gate) {
        return gate.getGateType() == null || !gate.getGateType().name().equals("LOCK");
    }

    private static int retentionOrDefault(FeatureGate gate) {
        Integer days = gate.getRetentionDays();
        return (days != null && days > 0) ? days : DEFAULT_RETENTION_DAYS;
    }
}
