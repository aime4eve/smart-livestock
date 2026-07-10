package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.shared.tenant.TenantContext;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * ACL implementation bridging Health context to Commerce subscription data.
 * <p>
 * Reads the current tenant from TenantContext, resolves its subscription tier,
 * then looks up feature gate configuration.
 */
@Component
public class HealthSubscriptionPortImpl implements HealthSubscriptionPort {

    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;

    private static final int DEFAULT_RETENTION_DAYS = 7;
    private static final String DEFAULT_TIER = "basic";

    public HealthSubscriptionPortImpl(SubscriptionRepository subscriptionRepository,
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
    public int getRetentionDays(String featureKey) {
        String tier = resolveTier();
        return featureGateRepository.findByTierAndFeatureKey(tier, featureKey)
                .map(FeatureGate::getRetentionDays)
                .filter(days -> days != null && days > 0)
                .orElse(DEFAULT_RETENTION_DAYS);
    }

    @Override
    public boolean hasFeature(String featureKey) {
        String tier = resolveTier();
        return featureGateRepository.findByTierAndFeatureKey(tier, featureKey)
                .filter(FeatureGate::isEnabled)
                .map(gate -> gate.getGateType() != GateType.LOCK)
                .orElse(false);
    }
}
