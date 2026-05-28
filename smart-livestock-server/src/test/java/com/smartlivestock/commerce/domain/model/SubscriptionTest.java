package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.SubscriptionCancelledEvent;
import com.smartlivestock.commerce.domain.model.event.SubscriptionRenewalFailedEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.event.*;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.*;

class SubscriptionTest {

    private static final Long TENANT_ID = 1L;

    // ── Factory helpers ──────────────────────────────────────────────

    private Subscription createTrialSubscription() {
        Instant now = Instant.now();
        Instant trialEnd = now.plusSeconds(14 * 86400);
        return Subscription.startTrial(TENANT_ID, "direct", now, trialEnd);
    }

    private Subscription createActiveSubscription() {
        Instant now = Instant.now();
        Instant expires = now.plusSeconds(30 * 86400);
        Subscription sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", expires);
        sub.clearDomainEvents();
        return sub;
    }

    // ── startTrial ───────────────────────────────────────────────────

    @Nested
    class StartTrial {

        @Test
        void setsTrialStatusAndFields() {
            Instant now = Instant.now();
            Instant trialEnd = now.plusSeconds(14 * 86400);

            Subscription sub = Subscription.startTrial(TENANT_ID, "direct", now, trialEnd);

            assertThat(sub.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
            assertThat(sub.getTier()).isEqualTo(SubscriptionTier.BASIC);
            assertThat(sub.getBillingModel()).isEqualTo("direct");
            assertThat(sub.getStartedAt()).isEqualTo(now);
            assertThat(sub.getTrialEndsAt()).isEqualTo(trialEnd);
            assertThat(sub.getExpiresAt()).isNull();
            assertThat(sub.getCancelledAt()).isNull();
            assertThat(sub.getBillingCycle()).isNull();
        }

        @Test
        void registersSubscriptionCreatedEvent() {
            Subscription sub = createTrialSubscription();

            assertThat(sub.getDomainEvents()).hasSize(1);
            SubscriptionCreatedEvent event = (SubscriptionCreatedEvent) sub.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getTier()).isEqualTo("BASIC");
        }
    }

    // ── activate ─────────────────────────────────────────────────────

    @Nested
    class Activate {

        @Test
        void activatesFromTrial() {
            Subscription sub = createTrialSubscription();
            sub.clearDomainEvents();

            Instant expires = Instant.now().plusSeconds(30 * 86400);
            sub.activate(SubscriptionTier.STANDARD, "monthly", expires);

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(sub.getTier()).isEqualTo(SubscriptionTier.STANDARD);
            assertThat(sub.getBillingCycle()).isEqualTo("monthly");
            assertThat(sub.getExpiresAt()).isEqualTo(expires);
        }

        @Test
        void registersSubscriptionCreatedEvent() {
            Subscription sub = createTrialSubscription();
            sub.clearDomainEvents();

            Instant expires = Instant.now().plusSeconds(30 * 86400);
            sub.activate(SubscriptionTier.STANDARD, "monthly", expires);

            assertThat(sub.getDomainEvents()).hasSize(1);
            SubscriptionCreatedEvent event = (SubscriptionCreatedEvent) sub.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getTier()).isEqualTo("STANDARD");
        }
    }

    // ── expireTrial ──────────────────────────────────────────────────

    @Nested
    class ExpireTrial {

        @Test
        void transitionsToFreeWithBasicTier() {
            Subscription sub = createTrialSubscription();
            sub.clearDomainEvents();

            sub.expireTrial();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.FREE);
            assertThat(sub.getTier()).isEqualTo(SubscriptionTier.BASIC);
        }

        @Test
        void registersTierChangedEvent() {
            Subscription sub = createTrialSubscription();
            sub.clearDomainEvents();

            sub.expireTrial();

            assertThat(sub.getDomainEvents()).hasSize(1);
            SubscriptionTierChangedEvent event = (SubscriptionTierChangedEvent) sub.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getOldTier()).isEqualTo("BASIC");
            assertThat(event.getNewTier()).isEqualTo("FREE");
        }

        @Test
        void rejectsFromNonTrial() {
            Subscription sub = createActiveSubscription();
            assertThatThrownBy(sub::expireTrial)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── effectiveTier / isTrialActive / isActiveOrTrial ──────────────

    @Nested
    class EffectiveTier {

        @Test
        void trialActive_returnsPremium() {
            Subscription sub = createTrialSubscription();
            // trialEndsAt is 14 days from now, so trial is active
            assertThat(sub.isTrialActive()).isTrue();
            assertThat(sub.effectiveTier()).isEqualTo(SubscriptionTier.PREMIUM);
        }

        @Test
        void trialExpired_returnsActualTier() {
            Instant past = Instant.now().minusSeconds(14 * 86400);
            Instant trialStart = past.minusSeconds(14 * 86400);
            Subscription sub = Subscription.startTrial(TENANT_ID, "direct", trialStart, past);
            // trialEndsAt is in the past
            assertThat(sub.isTrialActive()).isFalse();
            assertThat(sub.effectiveTier()).isEqualTo(SubscriptionTier.BASIC);
        }

        @Test
        void activeSubscription_returnsActualTier() {
            Subscription sub = createActiveSubscription();
            assertThat(sub.effectiveTier()).isEqualTo(SubscriptionTier.STANDARD);
        }

        @Test
        void isActiveOrTrial_active() {
            Subscription sub = createActiveSubscription();
            assertThat(sub.isActiveOrTrial()).isTrue();
        }

        @Test
        void isActiveOrTrial_trial() {
            Subscription sub = createTrialSubscription();
            assertThat(sub.isActiveOrTrial()).isTrue();
        }

        @Test
        void isActiveOrTrial_free() {
            Subscription sub = createTrialSubscription();
            sub.expireTrial();
            assertThat(sub.isActiveOrTrial()).isTrue();
        }

        @Test
        void isActiveOrTrial_suspended_false() {
            Subscription sub = createActiveSubscription();
            sub.suspend();
            assertThat(sub.isActiveOrTrial()).isFalse();
        }

        @Test
        void isActiveOrTrial_cancelled_false() {
            Subscription sub = createActiveSubscription();
            sub.cancel(Instant.now());
            assertThat(sub.isActiveOrTrial()).isFalse();
        }

        @Test
        void isActiveOrTrial_renewalFailed_false() {
            Subscription sub = createActiveSubscription();
            sub.markRenewalFailed();
            assertThat(sub.isActiveOrTrial()).isFalse();
        }

        @Test
        void isActiveOrTrial_expired_false() {
            Subscription sub = createActiveSubscription();
            sub.markExpired();
            assertThat(sub.isActiveOrTrial()).isFalse();
        }

        @Test
        void isTrialActive_nullTrialEndsAt_returnsFalse() {
            Subscription sub = createTrialSubscription();
            sub.setTrialEndsAt(null);
            assertThat(sub.isTrialActive()).isFalse();
        }
    }

    // ── changeTier ───────────────────────────────────────────────────

    @Nested
    class ChangeTier {

        @Test
        void fromFreeToActive() {
            Subscription sub = createTrialSubscription();
            sub.expireTrial(); // -> FREE
            sub.clearDomainEvents();

            Instant expires = Instant.now().plusSeconds(30 * 86400);
            sub.changeTier(SubscriptionTier.PREMIUM, "monthly", expires);

            assertThat(sub.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(sub.getBillingCycle()).isEqualTo("monthly");
            assertThat(sub.getExpiresAt()).isEqualTo(expires);
        }

        @Test
        void registersTierChangedEvent() {
            Subscription sub = createActiveSubscription();

            sub.changeTier(SubscriptionTier.PREMIUM, "monthly", sub.getExpiresAt());

            assertThat(sub.getDomainEvents()).hasSize(1);
            SubscriptionTierChangedEvent event = (SubscriptionTierChangedEvent) sub.getDomainEvents().get(0);
            assertThat(event.getOldTier()).isEqualTo("STANDARD");
            assertThat(event.getNewTier()).isEqualTo("PREMIUM");
        }

        @Test
        void fromTrial_transitionsToActive() {
            Subscription sub = createTrialSubscription();
            sub.clearDomainEvents();

            Instant expires = Instant.now().plusSeconds(30 * 86400);
            sub.changeTier(SubscriptionTier.STANDARD, "monthly", expires);

            assertThat(sub.getTier()).isEqualTo(SubscriptionTier.STANDARD);
            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(sub.getDomainEvents()).hasSize(1);
            SubscriptionTierChangedEvent event = (SubscriptionTierChangedEvent) sub.getDomainEvents().get(0);
            assertThat(event.getOldTier()).isEqualTo("BASIC");
            assertThat(event.getNewTier()).isEqualTo("STANDARD");
        }
    }

    // ── suspend / reactivate ─────────────────────────────────────────

    @Nested
    class SuspendAndReactivate {

        @Test
        void suspend_transitionsToSuspended() {
            Subscription sub = createActiveSubscription();

            sub.suspend();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.SUSPENDED);
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionSuspendedEvent.class);
        }

        @Test
        void reactivate_transitionsToActive() {
            Subscription sub = createActiveSubscription();
            sub.suspend();
            sub.clearDomainEvents();

            sub.reactivate();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionReactivatedEvent.class);
        }

        @Test
        void suspendRequiresActive() {
            Subscription sub = createTrialSubscription();
            assertThatThrownBy(sub::suspend)
                .isInstanceOf(DomainException.class);
        }
    }

    // ── markRenewalFailed / recoverFromRenewalFailure ────────────────

    @Nested
    class RenewalFailure {

        @Test
        void markRenewalFailed_transitionsToRenewalFailed() {
            Subscription sub = createActiveSubscription();

            sub.markRenewalFailed();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.RENEWAL_FAILED);
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionRenewalFailedEvent.class);
        }

        @Test
        void recoverFromRenewalFailure_transitionsToActive() {
            Subscription sub = createActiveSubscription();
            sub.markRenewalFailed();
            sub.clearDomainEvents();

            sub.recoverFromRenewalFailure();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionReactivatedEvent.class);
        }

        @Test
        void downgradeAfterRenewalFailure_transitionsToFree() {
            Subscription sub = createActiveSubscription();
            sub.markRenewalFailed();
            sub.clearDomainEvents();

            sub.downgradeAfterRenewalFailure();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.FREE);
            assertThat(sub.getTier()).isEqualTo(SubscriptionTier.BASIC);
            assertThat(sub.getDomainEvents()).hasSize(1);
            SubscriptionTierChangedEvent event = (SubscriptionTierChangedEvent) sub.getDomainEvents().get(0);
            assertThat(event.getNewTier()).isEqualTo("FREE");
        }
    }

    // ── cancel ───────────────────────────────────────────────────────

    @Nested
    class Cancel {

        @Test
        void cancelFromActive_setsCancelledAt() {
            Subscription sub = createActiveSubscription();
            Instant cancelledAt = Instant.now();

            sub.cancel(cancelledAt);

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.CANCELLED);
            assertThat(sub.getCancelledAt()).isEqualTo(cancelledAt);
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionCancelledEvent.class);
        }

        @Test
        void cancelFromTrial() {
            Subscription sub = createTrialSubscription();
            sub.clearDomainEvents();

            sub.cancel(Instant.now());

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.CANCELLED);
            assertThat(sub.getCancelledAt()).isNotNull();
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionCancelledEvent.class);
        }
    }

    // ── markExpired ──────────────────────────────────────────────────

    @Nested
    class MarkExpired {

        @Test
        void transitionsToExpired() {
            Subscription sub = createActiveSubscription();

            sub.markExpired();

            assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.EXPIRED);
            assertThat(sub.getDomainEvents()).hasSize(1);
            assertThat(sub.getDomainEvents().get(0)).isInstanceOf(SubscriptionExpiredEvent.class);
        }
    }

    // ── Illegal transitions ──────────────────────────────────────────

    @Nested
    class IllegalTransitions {

        @Test
        void activateFromActive_throwsStateConflict() {
            Subscription sub = createActiveSubscription();
            Instant expires = Instant.now().plusSeconds(30 * 86400);

            assertThatThrownBy(() -> sub.activate(SubscriptionTier.PREMIUM, "monthly", expires))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void reactivateFromActive_throwsStateConflict() {
            Subscription sub = createActiveSubscription();

            assertThatThrownBy(sub::reactivate)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void cancelFromCancelled_throwsStateConflict() {
            Subscription sub = createActiveSubscription();
            sub.cancel(Instant.now());
            sub.clearDomainEvents();

            assertThatThrownBy(() -> sub.cancel(Instant.now()))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void suspendFromSuspended_throwsStateConflict() {
            Subscription sub = createActiveSubscription();
            sub.suspend();

            assertThatThrownBy(sub::suspend)
                .isInstanceOf(DomainException.class);
        }

        @Test
        void markRenewalFailedFromTrial_throwsStateConflict() {
            Subscription sub = createTrialSubscription();

            assertThatThrownBy(sub::markRenewalFailed)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void recoverFromRenewalFailureWhenActive_throwsStateConflict() {
            Subscription sub = createActiveSubscription();

            assertThatThrownBy(sub::recoverFromRenewalFailure)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void downgradeFromActive_throwsStateConflict() {
            Subscription sub = createActiveSubscription();

            assertThatThrownBy(sub::downgradeAfterRenewalFailure)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void markExpiredFromCancelled_throwsStateConflict() {
            Subscription sub = createActiveSubscription();
            sub.cancel(Instant.now());

            assertThatThrownBy(sub::markExpired)
                .isInstanceOf(DomainException.class);
        }
    }
}
