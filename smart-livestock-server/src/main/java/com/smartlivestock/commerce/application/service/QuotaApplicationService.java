package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.application.port.QuotaCheckService;
import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.licensing.application.port.LicenseQuotaPort;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.MessageResolver;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Two-layer quota engine: license quota first (ONPREM only, design §10), then
 * subscription activity and feature gate rules.
 * <p>
 * T4 (NIX-184): when the licensing context exposes a quota for the feature key
 * (ONPREM + VALID current license + payload carries the key), the license quota
 * wins with an inclusive "usage &le; quota" LIMIT semantics and a dedicated
 * {@code license.quotaExceeded.detail} denial message. When no license quota
 * applies (HOSTED mode, no valid license, or key not covered), the pre-existing
 * FeatureGate behavior is unchanged.
 */
@Service
public class QuotaApplicationService implements QuotaCheckService {

    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;
    private final LicenseQuotaPort licenseQuotaPort;
    private final MessageResolver messageResolver;

    public QuotaApplicationService(SubscriptionRepository subscriptionRepository,
                                   FeatureGateRepository featureGateRepository,
                                   LicenseQuotaPort licenseQuotaPort,
                                   MessageResolver messageResolver) {
        this.subscriptionRepository = subscriptionRepository;
        this.featureGateRepository = featureGateRepository;
        this.licenseQuotaPort = licenseQuotaPort;
        this.messageResolver = messageResolver;
    }

    @Override
    public QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage) {
        Subscription sub = subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new DomainException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                "订阅不存在: tenantId=" + tenantId));

        if (!sub.isActiveOrTrial()) {
            return QuotaResult.denied("订阅未激活");
        }

        Optional<Integer> licenseQuota = licenseQuotaPort.findLicenseQuota(tenantId, featureKey);
        if (licenseQuota.isPresent()) {
            return checkLicenseQuota(featureKey, currentUsage, licenseQuota.get());
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

    /**
     * License quota semantics: usage at exactly the quota is still allowed
     * ("用量 ≤ 配额", design §10); only exceeding it is denied, with a
     * license-specific localized message.
     */
    private QuotaResult checkLicenseQuota(String featureKey, int currentUsage, int quota) {
        if (currentUsage <= quota) {
            return QuotaResult.allowed();
        }
        String reason = messageResolver.resolve("license.quotaExceeded.detail",
            new Object[]{featureKey, currentUsage, quota}, LocaleContextHolder.getLocale());
        return QuotaResult.denied(reason);
    }

    private FeatureGate loadGate(String featureKey, SubscriptionTier tier) {
        return featureGateRepository.findByTierAndFeatureKey(tier.name().toLowerCase(), featureKey)
            .orElseGet(FeatureGate::unrestricted);
    }
}
