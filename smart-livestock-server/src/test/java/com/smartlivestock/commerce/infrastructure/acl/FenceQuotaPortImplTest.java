package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.licensing.application.port.LicenseQuotaPort;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Limit-resolution semantics of the ranch→commerce fence quota ACL: the
 * same precedence as QuotaApplicationService (license quota first, then the
 * effective tier's feature_gates LIMIT row), with null = "unlimited".
 */
@ExtendWith(MockitoExtension.class)
class FenceQuotaPortImplTest {

    private static final long TENANT_ID = 7L;

    @Mock private LicenseQuotaPort licenseQuotaPort;
    @Mock private SubscriptionRepository subscriptionRepository;
    @Mock private FeatureGateRepository featureGateRepository;

    private FenceQuotaPortImpl port;

    @BeforeEach
    void setUp() {
        port = new FenceQuotaPortImpl(licenseQuotaPort, subscriptionRepository, featureGateRepository);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    private Subscription stubSubscription(SubscriptionTier tier) {
        Subscription sub = mock(Subscription.class);
        lenient().when(sub.isActiveOrTrial()).thenReturn(true);
        lenient().when(sub.effectiveTier()).thenReturn(tier);
        lenient().when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(sub));
        return sub;
    }

    @Test
    void resolvesLimitFromFeatureGateLimitRow() {
        TenantContext.setCurrentTenant(TENANT_ID);
        stubSubscription(SubscriptionTier.STANDARD);
        when(licenseQuotaPort.findLicenseQuota(TENANT_ID, "fence_management"))
                .thenReturn(Optional.empty());
        when(featureGateRepository.findByTierAndFeatureKey("standard", "fence_management"))
                .thenReturn(Optional.of(new FeatureGate(
                        "standard", "fence_management", GateType.LIMIT, 20, null, true)));

        assertEquals(20, port.resolveFenceManagementLimitForCurrentTenant());
    }

    @Test
    void licenseQuotaWinsOverFeatureGate() {
        TenantContext.setCurrentTenant(TENANT_ID);
        stubSubscription(SubscriptionTier.STANDARD);
        when(licenseQuotaPort.findLicenseQuota(TENANT_ID, "fence_management"))
                .thenReturn(Optional.of(50));

        assertEquals(50, port.resolveFenceManagementLimitForCurrentTenant());
        verifyNoInteractions(featureGateRepository);
    }

    @Test
    void enterpriseNoneGateResolvesToNull() {
        TenantContext.setCurrentTenant(TENANT_ID);
        stubSubscription(SubscriptionTier.ENTERPRISE);
        when(licenseQuotaPort.findLicenseQuota(TENANT_ID, "fence_management"))
                .thenReturn(Optional.empty());
        when(featureGateRepository.findByTierAndFeatureKey("enterprise", "fence_management"))
                .thenReturn(Optional.of(new FeatureGate(
                        "enterprise", "fence_management", GateType.NONE, null, null, true)));

        assertNull(port.resolveFenceManagementLimitForCurrentTenant());
    }

    @Test
    void missingGateRowResolvesToNull() {
        TenantContext.setCurrentTenant(TENANT_ID);
        stubSubscription(SubscriptionTier.STANDARD);
        when(licenseQuotaPort.findLicenseQuota(TENANT_ID, "fence_management"))
                .thenReturn(Optional.empty());
        when(featureGateRepository.findByTierAndFeatureKey("standard", "fence_management"))
                .thenReturn(Optional.empty());

        assertNull(port.resolveFenceManagementLimitForCurrentTenant());
    }

    @Test
    void inactiveSubscriptionResolvesToNull() {
        TenantContext.setCurrentTenant(TENANT_ID);
        Subscription sub = mock(Subscription.class);
        when(sub.isActiveOrTrial()).thenReturn(false);
        when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
        when(licenseQuotaPort.findLicenseQuota(TENANT_ID, "fence_management"))
                .thenReturn(Optional.empty());

        assertNull(port.resolveFenceManagementLimitForCurrentTenant());
    }

    @Test
    void noTenantContextResolvesToNullWithoutTouchingStores() {
        assertNull(port.resolveFenceManagementLimitForCurrentTenant());
        verifyNoInteractions(licenseQuotaPort, subscriptionRepository, featureGateRepository);
    }
}
