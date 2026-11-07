package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.ranch.domain.port.SceneGatePort;
import com.smartlivestock.shared.tenant.TenantContext;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * ACL implementation bridging the Ranch overview (NIX-389) to Commerce
 * subscription data. Mirrors the tier resolution of
 * HealthSubscriptionPortImpl (kept independent: the two ACLs bridge opposite
 * directions and must be able to evolve separately). The overview runs in a
 * user request context, so the request tenant comes from TenantContext.
 */
@Component("commerceSceneGatePort")
public class SceneGatePortImpl implements SceneGatePort {

    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;

    private static final String DEFAULT_TIER = "basic";

    public SceneGatePortImpl(SubscriptionRepository subscriptionRepository,
                             FeatureGateRepository featureGateRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.featureGateRepository = featureGateRepository;
    }

    private String resolveTier() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) return DEFAULT_TIER;
        return subscriptionRepository.findByTenantId(tenantId)
                .filter(Subscription::isActiveOrTrial)
                .map(sub -> sub.effectiveTier().name().toLowerCase())
                .orElse(DEFAULT_TIER);
    }

    @Override
    public boolean isLocked(String featureKey) {
        String tier = resolveTier();
        // Same gate semantics as HealthSubscriptionPortImpl.hasFeature: a
        // missing gate row or a disabled row locks the scene (fail-closed).
        return featureGateRepository.findByTierAndFeatureKey(tier, featureKey)
                .filter(FeatureGate::isEnabled)
                .map(gate -> gate.getGateType() == GateType.LOCK)
                .orElse(true);
    }
}
