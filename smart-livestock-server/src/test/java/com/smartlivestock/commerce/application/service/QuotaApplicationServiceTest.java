package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.domain.model.*;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class QuotaApplicationServiceTest {

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private FeatureGateRepository featureGateRepository;

    private QuotaApplicationService createService() {
        return new QuotaApplicationService(subscriptionRepository, featureGateRepository);
    }

    private Subscription createActiveSubscription(SubscriptionTier tier) {
        Instant now = Instant.now();
        Instant trialEnd = now.plusSeconds(14 * 86400);
        Subscription sub = Subscription.startTrial(1L, "direct", now, trialEnd);
        sub.activate(tier, "monthly", now.plusSeconds(30 * 86400));
        return sub;
    }

    private Subscription createSuspendedSubscription() {
        Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
        sub.suspend();
        return sub;
    }

    private Subscription createTrialSubscription() {
        Instant now = Instant.now();
        Instant trialEnd = now.plusSeconds(14 * 86400);
        return Subscription.startTrial(1L, "direct", now, trialEnd);
    }

    // ── Layer 1: Subscription status check ───────────────────────────

    @Nested
    class SubscriptionStatusCheck {

        @Test
        void subscriptionNotFound_throwsDomainException() {
            when(subscriptionRepository.findByTenantId(999L)).thenReturn(Optional.empty());

            QuotaApplicationService service = createService();

            assertThatThrownBy(() -> service.checkQuota(999L, "any_feature", 0))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.SUBSCRIPTION_NOT_FOUND));
        }

        @Test
        void suspendedSubscription_deniedRegardlessOfGate() {
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(createSuspendedSubscription()));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "any_feature", 0);

            assertThat(result.isAllowed()).isFalse();
            assertThat(result.getReason()).contains("SUSPENDED");
        }

        @Test
        void cancelledSubscription_denied() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            sub.cancel(Instant.now());
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(sub));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "any_feature", 0);

            assertThat(result.isAllowed()).isFalse();
        }

        @Test
        void expiredSubscription_denied() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            sub.markExpired();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(sub));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "any_feature", 0);

            assertThat(result.isAllowed()).isFalse();
        }

        @Test
        void renewalFailedSubscription_denied() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            sub.markRenewalFailed();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(sub));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "any_feature", 0);

            assertThat(result.isAllowed()).isFalse();
        }
    }

    // ── Layer 2: Gate rules ──────────────────────────────────────────

    @Nested
    class GateTypeNone {

        @Test
        void allowsAccess() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.PREMIUM)));
            when(featureGateRepository.findByTierAndFeatureKey("premium", "api_access"))
                .thenReturn(Optional.of(new FeatureGate("premium", "api_access", "none", null, null, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "api_access", 0);

            assertThat(result.isAllowed()).isTrue();
            assertThat(result.getReason()).isNull();
        }

        @Test
        void missingGate_treatedAsNone() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.PREMIUM)));
            when(featureGateRepository.findByTierAndFeatureKey("premium", "unknown_feature"))
                .thenReturn(Optional.empty());

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "unknown_feature", 0);

            assertThat(result.isAllowed()).isTrue();
        }
    }

    @Nested
    class GateTypeLock {

        @Test
        void enabledLock_allowsAccess() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.STANDARD)));
            when(featureGateRepository.findByTierAndFeatureKey("standard", "alert_management"))
                .thenReturn(Optional.of(new FeatureGate("standard", "alert_management", "lock", null, null, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "alert_management", 0);

            assertThat(result.isAllowed()).isTrue();
        }

        @Test
        void disabledLock_deniesAccess() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.BASIC)));
            when(featureGateRepository.findByTierAndFeatureKey("basic", "advanced_analytics"))
                .thenReturn(Optional.of(new FeatureGate("basic", "advanced_analytics", "lock", null, null, false)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "advanced_analytics", 0);

            assertThat(result.isAllowed()).isFalse();
            assertThat(result.getReason()).contains("advanced_analytics");
        }
    }

    @Nested
    class GateTypeLimit {

        @Test
        void underLimit_allowsAccess() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.BASIC)));
            when(featureGateRepository.findByTierAndFeatureKey("basic", "livestock_management"))
                .thenReturn(Optional.of(new FeatureGate("basic", "livestock_management", "limit", 50, null, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "livestock_management", 49);

            assertThat(result.isAllowed()).isTrue();
        }

        @Test
        void atLimit_deniesAccess() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.BASIC)));
            when(featureGateRepository.findByTierAndFeatureKey("basic", "livestock_management"))
                .thenReturn(Optional.of(new FeatureGate("basic", "livestock_management", "limit", 50, null, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "livestock_management", 50);

            assertThat(result.isAllowed()).isFalse();
            assertThat(result.getReason()).contains("50");
        }

        @Test
        void overLimit_deniesAccess() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.BASIC)));
            when(featureGateRepository.findByTierAndFeatureKey("basic", "fence_management"))
                .thenReturn(Optional.of(new FeatureGate("basic", "fence_management", "limit", 5, null, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "fence_management", 10);

            assertThat(result.isAllowed()).isFalse();
        }
    }

    @Nested
    class GateTypeFilter {

        @Test
        void allowedWithRetentionDays() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createActiveSubscription(SubscriptionTier.STANDARD)));
            when(featureGateRepository.findByTierAndFeatureKey("standard", "advanced_analytics"))
                .thenReturn(Optional.of(new FeatureGate("standard", "advanced_analytics", "filter", null, 30, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "advanced_analytics", 0);

            assertThat(result.isAllowed()).isTrue();
            assertThat(result.getRetentionDays()).isEqualTo(30);
        }
    }

    // ── Trial subscription ───────────────────────────────────────────

    @Nested
    class TrialSubscription {

        @Test
        void trialUsesEffectiveTierPremium() {
            when(subscriptionRepository.findByTenantId(1L))
                .thenReturn(Optional.of(createTrialSubscription()));
            when(featureGateRepository.findByTierAndFeatureKey("premium", "api_access"))
                .thenReturn(Optional.of(new FeatureGate("premium", "api_access", "none", null, null, true)));

            QuotaApplicationService service = createService();
            QuotaResult result = service.checkQuota(1L, "api_access", 0);

            assertThat(result.isAllowed()).isTrue();
        }
    }
}
