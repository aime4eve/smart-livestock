package com.smartlivestock.health.infrastructure.acl;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.GateType;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * NIX-381 Task 0 fix: scheduler threads carry no TenantContext, so the gate
 * must resolve the tier from an explicit tenant id. These tests pin that the
 * ThreadLocal is never consulted by {@link HealthSubscriptionPortImpl
 * #hasFeatureForTenant} while {@code hasFeature} keeps its old behavior.
 */
@ExtendWith(MockitoExtension.class)
class HealthSubscriptionPortImplTest {

    private static final Long TENANT_ID = 7L;
    private static final String FEATURE = "calving_warning";

    @Mock private SubscriptionRepository subscriptionRepository;
    @Mock private FeatureGateRepository featureGateRepository;

    private HealthSubscriptionPortImpl port;

    @BeforeEach
    void setUp() {
        port = new HealthSubscriptionPortImpl(subscriptionRepository, featureGateRepository);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    private Subscription activeSubscription(SubscriptionTier tier) {
        Subscription subscription = new Subscription();
        subscription.setTenantId(TENANT_ID);
        subscription.setTier(tier);
        subscription.setStatus(SubscriptionStatus.ACTIVE);
        return subscription;
    }

    private FeatureGate gate(String tier, GateType gateType, boolean enabled) {
        return new FeatureGate(tier, FEATURE, gateType, null, null, enabled);
    }

    @Test
    void premiumTenant_openGate_allowed() {
        when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(activeSubscription(SubscriptionTier.PREMIUM)));
        when(featureGateRepository.findByTierAndFeatureKey("premium", FEATURE))
                .thenReturn(Optional.of(gate("premium", GateType.NONE, true)));

        assertThat(port.hasFeatureForTenant(TENANT_ID, FEATURE)).isTrue();
    }

    @Test
    void lockedGate_deniedEvenWhenEnabled() {
        when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(activeSubscription(SubscriptionTier.BASIC)));
        when(featureGateRepository.findByTierAndFeatureKey("basic", FEATURE))
                .thenReturn(Optional.of(gate("basic", GateType.LOCK, true)));

        assertThat(port.hasFeatureForTenant(TENANT_ID, FEATURE)).isFalse();
    }

    @Test
    void disabledGate_denied() {
        when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(activeSubscription(SubscriptionTier.PREMIUM)));
        when(featureGateRepository.findByTierAndFeatureKey("premium", FEATURE))
                .thenReturn(Optional.of(gate("premium", GateType.NONE, false)));

        assertThat(port.hasFeatureForTenant(TENANT_ID, FEATURE)).isFalse();
    }

    @Test
    void missingGate_denied() {
        when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(activeSubscription(SubscriptionTier.PREMIUM)));
        when(featureGateRepository.findByTierAndFeatureKey("premium", FEATURE))
                .thenReturn(Optional.empty());

        assertThat(port.hasFeatureForTenant(TENANT_ID, FEATURE)).isFalse();
    }

    @Test
    void nullTenantOrMissingSubscription_fallsBackToBasicGate() {
        when(featureGateRepository.findByTierAndFeatureKey("basic", FEATURE))
                .thenReturn(Optional.of(gate("basic", GateType.LOCK, true)));

        assertThat(port.hasFeatureForTenant(null, FEATURE)).isFalse();

        when(subscriptionRepository.findByTenantId(99L)).thenReturn(Optional.empty());
        assertThat(port.hasFeatureForTenant(99L, FEATURE)).isFalse();
    }

    /** The decisive check: the ThreadLocal holds a DIFFERENT tenant (99L,
     *  deliberately not stubbed — the impl must never query it) while the
     *  explicit tenant is premium. A ThreadLocal-reading implementation would
     *  resolve to the basic tier, find no gate, and return false. */
    @Test
    void hasFeatureForTenant_neverReadsTenantContext() {
        TenantContext.setCurrentTenant(99L);
        when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(activeSubscription(SubscriptionTier.PREMIUM)));
        when(featureGateRepository.findByTierAndFeatureKey("premium", FEATURE))
                .thenReturn(Optional.of(gate("premium", GateType.NONE, true)));

        assertThat(port.hasFeatureForTenant(TENANT_ID, FEATURE)).isTrue();
        org.mockito.Mockito.verify(subscriptionRepository,
                org.mockito.Mockito.times(1)).findByTenantId(TENANT_ID);
    }

    @Test
    void hasFeature_stillResolvesThroughTenantContext() {
        TenantContext.setCurrentTenant(TENANT_ID);
        when(subscriptionRepository.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(activeSubscription(SubscriptionTier.PREMIUM)));
        when(featureGateRepository.findByTierAndFeatureKey("premium", FEATURE))
                .thenReturn(Optional.of(gate("premium", GateType.NONE, true)));

        assertThat(port.hasFeature(FEATURE)).isTrue();
    }
}
