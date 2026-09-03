package com.smartlivestock.licensing;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.commerce.infrastructure.acl.CommerceLicenseAdapter;
import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the commerce-side adapter implementing the
 * licensing-owned {@link LicenseSubscriptionPort} (NIX-184 T3).
 */
@ExtendWith(MockitoExtension.class)
class CommerceLicenseAdapterTest {

    private static final Long TENANT_ID = 1L;

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private DomainEventPublisher domainEventPublisher;

    private CommerceLicenseAdapter createAdapter() {
        return new CommerceLicenseAdapter(subscriptionRepository, domainEventPublisher);
    }

    private Subscription createTrialSubscription() {
        Instant now = Instant.now();
        return Subscription.startTrial(TENANT_ID, "direct", now, now.plus(Duration.ofDays(14)));
    }

    private Subscription createActiveSubscription(SubscriptionTier tier) {
        Subscription sub = createTrialSubscription();
        sub.activate(tier, "monthly", Instant.now().plus(Duration.ofDays(30)));
        return sub;
    }

    // ── findSubscription ─────────────────────────────────────────────

    @Nested
    class FindSubscription {

        @Test
        void mapsSnapshotFields() {
            Subscription sub = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            Optional<LicenseSubscriptionPort.LicenseSubscriptionSnapshot> snapshot =
                createAdapter().findSubscription(TENANT_ID);

            assertThat(snapshot).isPresent();
            assertThat(snapshot.get().status()).isEqualTo("TRIAL");
            assertThat(snapshot.get().trialEndsAt()).isEqualTo(sub.getTrialEndsAt());
            assertThat(snapshot.get().trialActive()).isTrue();
        }

        @Test
        void emptyWhenNoSubscription() {
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThat(createAdapter().findSubscription(TENANT_ID)).isEmpty();
        }
    }

    // ── applyTrialLicense ────────────────────────────────────────────

    @Nested
    class ApplyTrialLicense {

        @Test
        void noSubscription_createsTrial() {
            Instant trialEndsAt = Instant.now().plus(Duration.ofDays(365));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().applyTrialLicense(TENANT_ID, trialEndsAt);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            Subscription saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
            assertThat(saved.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(saved.getTrialEndsAt()).isEqualTo(trialEndsAt);
            assertThat(saved.getBillingModel()).isEqualTo("direct");
            verify(domainEventPublisher).publishDomainEvents(saved);
        }

        @Test
        void existingTrial_extendsTrialEnd() {
            Subscription sub = createTrialSubscription();
            Instant newEnd = sub.getTrialEndsAt().plus(Duration.ofDays(365));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().applyTrialLicense(TENANT_ID, newEnd);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            assertThat(captor.getValue().getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
            assertThat(captor.getValue().getTrialEndsAt()).isEqualTo(newEnd);
        }

        @Test
        void existingActive_throwsStateConflict() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            assertThatThrownBy(() -> createAdapter()
                .applyTrialLicense(TENANT_ID, Instant.now().plus(Duration.ofDays(365))))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.STATE_CONFLICT));

            verify(subscriptionRepository, never()).save(any(Subscription.class));
        }
    }

    // ── applyActiveLicense ───────────────────────────────────────────

    @Nested
    class ApplyActiveLicense {

        @Test
        void fromTrial_activatesWithTier() {
            Subscription sub = createTrialSubscription();
            Instant expiresAt = Instant.now().plus(Duration.ofDays(365));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().applyActiveLicense(TENANT_ID, "PREMIUM", expiresAt);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            Subscription saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(saved.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
            assertThat(saved.getExpiresAt()).isEqualTo(expiresAt);
        }

        @Test
        void fromFree_transitionsToActive() {
            Subscription sub = createTrialSubscription();
            sub.expireTrial();
            Instant expiresAt = Instant.now().plus(Duration.ofDays(365));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().applyActiveLicense(TENANT_ID, "BASIC", expiresAt);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            Subscription saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(saved.getTier()).isEqualTo(SubscriptionTier.BASIC);
        }

        @Test
        void active_updatesTierAndStaysActive() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            Instant expiresAt = sub.getExpiresAt().plus(Duration.ofDays(335));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().applyActiveLicense(TENANT_ID, "ENTERPRISE", expiresAt);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            Subscription saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(saved.getTier()).isEqualTo(SubscriptionTier.ENTERPRISE);
            assertThat(saved.getBillingCycle()).isEqualTo("monthly");
        }

        @Test
        void suspended_throwsStateConflict() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            sub.suspend();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            assertThatThrownBy(() -> createAdapter()
                .applyActiveLicense(TENANT_ID, "BASIC", Instant.now().plus(Duration.ofDays(365))))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.STATE_CONFLICT));

            verify(subscriptionRepository, never()).save(any(Subscription.class));
        }

        @Test
        void lowercaseTierName_isAccepted() {
            Subscription sub = createTrialSubscription();
            Instant expiresAt = Instant.now().plus(Duration.ofDays(365));
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().applyActiveLicense(TENANT_ID, "standard", expiresAt);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            assertThat(captor.getValue().getTier()).isEqualTo(SubscriptionTier.STANDARD);
        }

        @Test
        void unknownTier_throwsValidationError() {
            Subscription sub = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            assertThatThrownBy(() -> createAdapter()
                .applyActiveLicense(TENANT_ID, "GOLD", Instant.now().plus(Duration.ofDays(365))))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.VALIDATION_ERROR));
        }

        @Test
        void missingSubscription_throwsNotFound() {
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> createAdapter()
                .applyActiveLicense(TENANT_ID, "BASIC", Instant.now().plus(Duration.ofDays(365))))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.SUBSCRIPTION_NOT_FOUND));
        }
    }

    // ── downgradeForLicense ──────────────────────────────────────────

    @Nested
    class DowngradeForLicense {

        @Test
        void fromTrial_downgradesToFreeBasic() {
            Subscription sub = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().downgradeForLicense(TENANT_ID);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            Subscription saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(SubscriptionStatus.FREE);
            assertThat(saved.getTier()).isEqualTo(SubscriptionTier.BASIC);
        }

        @Test
        void fromRenewalFailed_downgradesToFreeBasic() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            sub.markRenewalFailed();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().downgradeForLicense(TENANT_ID);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            Subscription saved = captor.getValue();
            assertThat(saved.getStatus()).isEqualTo(SubscriptionStatus.FREE);
            assertThat(saved.getTier()).isEqualTo(SubscriptionTier.BASIC);
        }

        @Test
        void fromFree_isIdempotent() {
            Subscription sub = createTrialSubscription();
            sub.expireTrial();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().downgradeForLicense(TENANT_ID);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            assertThat(captor.getValue().getStatus()).isEqualTo(SubscriptionStatus.FREE);
        }

        @Test
        void fromActive_throwsStateConflict() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            assertThatThrownBy(() -> createAdapter().downgradeForLicense(TENANT_ID))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.STATE_CONFLICT));

            verify(subscriptionRepository, never()).save(any(Subscription.class));
        }
    }

    // ── suspendForLicense ────────────────────────────────────────────

    @Nested
    class SuspendForLicense {

        @Test
        void fromActive_suspends() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().suspendForLicense(TENANT_ID, "license suspended by admin");

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            assertThat(captor.getValue().getStatus()).isEqualTo(SubscriptionStatus.SUSPENDED);
        }

        @Test
        void fromSuspended_isIdempotent() {
            Subscription sub = createActiveSubscription(SubscriptionTier.STANDARD);
            sub.suspend();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));
            when(subscriptionRepository.save(any(Subscription.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

            createAdapter().suspendForLicense(TENANT_ID, "repeat");

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(subscriptionRepository).save(captor.capture());
            assertThat(captor.getValue().getStatus()).isEqualTo(SubscriptionStatus.SUSPENDED);
        }

        @Test
        void fromTrial_throwsStateConflict() {
            Subscription sub = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(sub));

            assertThatThrownBy(() -> createAdapter().suspendForLicense(TENANT_ID, "reason"))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.STATE_CONFLICT));

            verify(subscriptionRepository, never()).save(any(Subscription.class));
        }

        @Test
        void missingSubscription_throwsNotFound() {
            when(subscriptionRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> createAdapter().suspendForLicense(TENANT_ID, "reason"))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode())
                    .isEqualTo(ErrorCode.SUBSCRIPTION_NOT_FOUND));
        }
    }
}
