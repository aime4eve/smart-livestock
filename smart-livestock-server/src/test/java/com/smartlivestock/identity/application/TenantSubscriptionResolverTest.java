package com.smartlivestock.identity.application;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.identity.application.TenantSubscriptionResolver.SubscriptionSnapshot;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for TenantSubscriptionResolver (NIX-323): tier degradation
 * ("degrade, don't reject" ruling 2026-10-26) and the short-lived cache.
 */
@ExtendWith(MockitoExtension.class)
class TenantSubscriptionResolverTest {

    private static final Long TENANT_ID = 7L;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Nested
    class TierResolution {

        @Test
        void activeSubscriptionKeepsItsTier() {
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    Instant.now().minusSeconds(60), Instant.now().plusSeconds(3600));
            sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plusSeconds(30 * 24 * 3600));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            SubscriptionSnapshot snapshot = new TenantSubscriptionResolver(subscriptionRepository).resolve(TENANT_ID);

            assertThat(snapshot.status()).isEqualTo("ACTIVE");
            assertThat(snapshot.tier()).isEqualTo("standard");
            assertThat(snapshot.trialActive()).isFalse();
        }

        @Test
        void activeTrialResolvesToPremium() {
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    Instant.now().minusSeconds(60), Instant.now().plusSeconds(3600));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            SubscriptionSnapshot snapshot = new TenantSubscriptionResolver(subscriptionRepository).resolve(TENANT_ID);

            assertThat(snapshot.status()).isEqualTo("TRIAL");
            assertThat(snapshot.tier()).isEqualTo("premium");
            assertThat(snapshot.trialActive()).isTrue();
        }

        @Test
        void expiredSubscriptionDegradesToBasic() {
            // ACTIVE -> markExpired() -> EXPIRED is the real domain path.
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    Instant.now().minusSeconds(10_000), Instant.now().plusSeconds(3600));
            sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plusSeconds(30 * 24 * 3600));
            sub.markExpired();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            SubscriptionSnapshot snapshot = new TenantSubscriptionResolver(subscriptionRepository).resolve(TENANT_ID);

            assertThat(snapshot.status()).isEqualTo("EXPIRED");
            assertThat(snapshot.tier()).isEqualTo("basic");
        }

        @Test
        void freeSubscriptionDegradesToBasic() {
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    Instant.now().minusSeconds(10_000), Instant.now().minusSeconds(60));
            sub.expireTrial();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            SubscriptionSnapshot snapshot = new TenantSubscriptionResolver(subscriptionRepository).resolve(TENANT_ID);

            assertThat(snapshot.status()).isEqualTo("FREE");
            assertThat(snapshot.tier()).isEqualTo("basic");
        }

        @Test
        void missingSubscriptionIsNoneAndBasic() {
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            SubscriptionSnapshot snapshot = new TenantSubscriptionResolver(subscriptionRepository).resolve(TENANT_ID);

            assertThat(snapshot.status()).isEqualTo("NONE");
            assertThat(snapshot.tier()).isEqualTo("basic");
        }

        @Test
        void nullTenantIsNoneAndBasic() {
            SubscriptionSnapshot snapshot = new TenantSubscriptionResolver(subscriptionRepository).resolve(null);

            assertThat(snapshot.status()).isEqualTo("NONE");
            assertThat(snapshot.tier()).isEqualTo("basic");
        }
    }

    @Nested
    class Cache {

        @Test
        void secondResolveWithinTtlHitsCache() {
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    Instant.now().minusSeconds(60), Instant.now().plusSeconds(3600));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            TenantSubscriptionResolver resolver = new TenantSubscriptionResolver(subscriptionRepository);
            resolver.resolve(TENANT_ID);
            resolver.resolve(TENANT_ID);

            verify(subscriptionRepository, times(1)).findByTenantId(TENANT_ID);
        }

        @Test
        void evictForcesFreshLookup() {
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct",
                    Instant.now().minusSeconds(60), Instant.now().plusSeconds(3600));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            TenantSubscriptionResolver resolver = new TenantSubscriptionResolver(subscriptionRepository);
            resolver.resolve(TENANT_ID);
            resolver.evictTenant(TENANT_ID);
            resolver.resolve(TENANT_ID);

            verify(subscriptionRepository, times(2)).findByTenantId(TENANT_ID);
        }
    }
}
