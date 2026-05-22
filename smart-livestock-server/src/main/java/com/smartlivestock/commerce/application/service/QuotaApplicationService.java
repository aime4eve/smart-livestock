package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.application.port.QuotaCheckService;
import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.shared.common.DomainException;
import org.springframework.stereotype.Service;
import com.smartlivestock.shared.common.ErrorCode;

/**
 * Two-layer quota engine: checks subscription activity first, then feature gate rules.
 */
@Service
public class QuotaApplicationService implements QuotaCheckService {

    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;

    public QuotaApplicationService(SubscriptionRepository subscriptionRepository,
                                   FeatureGateRepository featureGateRepository) {
        this.subscriptionRepository = subscriptionRepository;
        this.featureGateRepository = featureGateRepository;
    }

    @Override
    public QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage) {
        Subscription sub = subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new DomainException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                "订阅不存在: tenantId=" + tenantId));

        if (!sub.isActiveOrTrial()) {
            return QuotaResult.denied("订阅未激活");
        }

        FeatureGate gate = loadGate(featureKey, sub.effectiveTier());
        return switch (gate.getGateType()) {
            case NONE -> QuotaResult.allowed();
            case LOCK -> gate.isEnabled()
                ? QuotaResult.allowed()
                : QuotaResult.denied("功能 " + featureKey + " 当前 Tier 不可用");
            case LIMIT -> currentUsage < gate.getLimitValue()
                ? QuotaResult.allowed()
                : QuotaResult.denied("已达到上限 " + gate.getLimitValue() + "，当前: " + currentUsage);
            case FILTER -> QuotaResult.allowedWithRetention(gate.getRetentionDays());
        };
    }

    private FeatureGate loadGate(String featureKey, SubscriptionTier tier) {
        return featureGateRepository.findByTierAndFeatureKey(tier.name().toLowerCase(), featureKey)
            .orElseGet(FeatureGate::unrestricted);
    }
}
