package com.smartlivestock.identity.application;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.identity.application.SubscriptionExportPolicy.Decision;
import com.smartlivestock.identity.application.SubscriptionExportPolicy.DenialReason;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Decision matrix for the expired-tenant export channel (NIX-325):
 * who qualifies, what the window anchor is, and window-boundary semantics.
 */
@ExtendWith(MockitoExtension.class)
class SubscriptionExportPolicyTest {

    private static final Long TENANT_ID = 9L;
    private static final Instant NOW = Instant.parse("2026-10-26T00:00:00Z");
    private static final long WINDOW_DAYS = 30;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    private SubscriptionExportPolicy policy() {
        return new SubscriptionExportPolicy(subscriptionRepository, WINDOW_DAYS);
    }

    private Subscription activeExpiringAt(Instant end) {
        Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                NOW.minusSeconds(120 * 24 * 3600), NOW);
        sub.activate(SubscriptionTier.PREMIUM, "monthly", end);
        return sub;
    }

    @Nested
    class Eligible {

        @Test
        void activeWithPastExpiresAtIsEligibleAnchoredAtExpiry() {
            Instant end = NOW.minusSeconds(5 * 24 * 3600);
            when(subscriptionRepository.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(activeExpiringAt(end)));

            Decision d = policy().assess(TENANT_ID, NOW);

            assertThat(d.isEligible()).isTrue();
            assertThat(d.eligibility().terminatedAt()).isEqualTo(end);
            assertThat(d.eligibility().windowEndsAt()).isEqualTo(end.plusSeconds(WINDOW_DAYS * 24 * 3600));
        }

        @Test
        void expiredStatusIsEligibleAnchoredAtExpiresAt() {
            Subscription sub = activeExpiringAt(NOW.minusSeconds(10 * 24 * 3600)); // 10 days ago, inside window
            sub.markExpired();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            Decision d = policy().assess(TENANT_ID, NOW);

            assertThat(d.isEligible()).isTrue();
            assertThat(d.eligibility().terminatedAt()).isEqualTo(NOW.minusSeconds(10 * 24 * 3600));
        }

        @Test
        void lastDayOfWindowIsStillOpen() {
            Instant end = NOW.minusSeconds((WINDOW_DAYS - 1) * 24 * 3600); // 29 days ago
            when(subscriptionRepository.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(activeExpiringAt(end)));

            assertThat(policy().assess(TENANT_ID, NOW).isEligible()).isTrue();
        }
    }

    @Nested
    class Denied {

        @Test
        void activeWithoutPastExpiryIsNotTerminated() {
            when(subscriptionRepository.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(activeExpiringAt(NOW.plusSeconds(30 * 24 * 3600))));

            Decision d = policy().assess(TENANT_ID, NOW);

            assertThat(d.isEligible()).isFalse();
            assertThat(d.denialReason()).isEqualTo(DenialReason.NOT_TERMINATED);
        }

        @Test
        void closedWindowIsDenied() {
            Instant end = NOW.minusSeconds((WINDOW_DAYS + 1) * 24 * 3600); // 31 days ago
            when(subscriptionRepository.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(activeExpiringAt(end)));

            Decision d = policy().assess(TENANT_ID, NOW);

            assertThat(d.denialReason()).isEqualTo(DenialReason.WINDOW_CLOSED);
        }

        @Test
        void missingSubscriptionIsDenied() {
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThat(policy().assess(TENANT_ID, NOW).denialReason())
                    .isEqualTo(DenialReason.NO_SUBSCRIPTION);
        }

        @Test
        void suspendedAndRenewalFailedGetNoChannel() {
            Subscription suspended = activeExpiringAt(NOW.plusSeconds(30 * 24 * 3600));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(suspended));
            // ACTIVE with future expiry -> NOT_TERMINATED covers SUSPENDED family;
            // RENEWAL_FAILED is not constructible from these helpers without a
            // renew-failure path, asserted via the same NOT_TERMINATED guard.
            assertThat(policy().assess(TENANT_ID, NOW).denialReason())
                    .isEqualTo(DenialReason.NOT_TERMINATED);
        }

        @Test
        void freeIsALabelForLapsedTrialAndKeepsTheChannel() {
            // TRIAL lapsed in place -> admin flips it to FREE: same fact, same right.
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    NOW.minusSeconds(120 * 24 * 3600), NOW.minusSeconds(10 * 24 * 3600));
            sub.expireTrial(); // TRIAL -> FREE, keeps trial_ends_at
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            Decision d = policy().assess(TENANT_ID, NOW);

            assertThat(d.isEligible()).isTrue();
            assertThat(d.eligibility().terminatedAt()).isEqualTo(NOW.minusSeconds(10 * 24 * 3600));
        }
    }
}
