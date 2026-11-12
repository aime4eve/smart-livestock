package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.licensing.application.port.LicenseQuotaPort;
import com.smartlivestock.ranch.domain.port.FenceQuotaPort;
import com.smartlivestock.shared.tenant.TenantContext;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * ACL implementation bridging the Ranch fence track-draft quota pre-check
 * to Commerce/Licensing. Mirrors the resolution order of
 * QuotaApplicationService (license quota first, then the effective tier's
 * feature_gates LIMIT row) but only extracts the limit value: denial
 * decisions stay with the @QuotaCheck interceptor on the write path.
 */
@Component("commerceFenceQuotaPort")
public class FenceQuotaPortImpl implements FenceQuotaPort {

    private static final String FEATURE_FENCE_MANAGEMENT = "fence_management";

    private final LicenseQuotaPort licenseQuotaPort;
    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;

    public FenceQuotaPortImpl(LicenseQuotaPort licenseQuotaPort,
                              SubscriptionRepository subscriptionRepository,
                              FeatureGateRepository featureGateRepository) {
        this.licenseQuotaPort = licenseQuotaPort;
        this.subscriptionRepository = subscriptionRepository;
        this.featureGateRepository = featureGateRepository;
    }

    @Override
    public Integer resolveFenceManagementLimitForCurrentTenant() {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return null;
        }
        Optional<Integer> licenseQuota = licenseQuotaPort.findLicenseQuota(tenantId, FEATURE_FENCE_MANAGEMENT);
        if (licenseQuota.isPresent()) {
            return licenseQuota.get();
        }
        return subscriptionRepository.findByTenantId(tenantId)
                .filter(Subscription::isActiveOrTrial)
                .flatMap(sub -> featureGateRepository.findByTierAndFeatureKey(
                        sub.effectiveTier().name().toLowerCase(), FEATURE_FENCE_MANAGEMENT))
                .filter(gate -> gate.isEnabled() && gate.getGateType() == GateType.LIMIT)
                .map(FeatureGate::getLimitValue)
                .orElse(null);
    }
}
