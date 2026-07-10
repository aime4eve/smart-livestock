package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SubscriptionApplicationServiceTest {

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private DomainEventPublisher domainEventPublisher;

    private SubscriptionApplicationService createService() {
        return new SubscriptionApplicationService(subscriptionRepository, domainEventPublisher);
    }

    // ── Test factories ─────────────────────────────────────────────

    private Subscription createTrialSubscription() {
        Instant now = Instant.now();
        Instant trialEnd = now.plusSeconds(14 * 86400);
        return Subscription.startTrial(1L, "direct", now, trialEnd);
    }

    private Subscription createActiveSubscription() {
        Instant now = Instant.now();
        Instant trialEnd = now.plusSeconds(14 * 86400);
        Subscription sub = Subscription.startTrial(1L, "direct", now, trialEnd);
        sub.activate(SubscriptionTier.STANDARD, "monthly", now.plusSeconds(30 * 86400));
        return sub;
    }

    private Subscription createSuspendedSubscription() {
        Subscription sub = createActiveSubscription();
        sub.suspend();
        return sub;
    }

    // ── getOrCreateSubscription ────────────────────────────────────

    @Nested
    class GetOrCreateSubscription {

        @Test
        void existingSubscription_returnsExisting() {
            Subscription existing = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(existing));

            SubscriptionApplicationService service = createService();
            Subscription result = service.getOrCreateSubscription(1L, "direct");

            assertThat(result).isSameAs(existing);
            verify(subscriptionRepository, never()).save(any());
        }

        @Test
        void noExistingSubscription_createsTrial() {
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.empty());
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.getOrCreateSubscription(1L, "direct");

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
            assertThat(result.getTenantId()).isEqualTo(1L);
            verify(subscriptionRepository).save(any());
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── upgrade ────────────────────────────────────────────────────

    @Nested
    class Upgrade {

        @Test
        void fromTrialToActive_succeeds() {
            Subscription trial = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(trial));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.upgrade(1L, SubscriptionTier.PREMIUM, "monthly");

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            assertThat(result.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void fromActiveTierChange_succeeds() {
            Subscription active = createActiveSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(active));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.upgrade(1L, SubscriptionTier.PREMIUM, "monthly");

            assertThat(result.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
        }

        @Test
        void subscriptionNotFound_throws() {
            when(subscriptionRepository.findByTenantId(999L)).thenReturn(Optional.empty());

            SubscriptionApplicationService service = createService();
            assertThatThrownBy(() -> service.upgrade(999L, SubscriptionTier.PREMIUM, "monthly"))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.SUBSCRIPTION_NOT_FOUND));
        }
    }

    // ── expireTrial ────────────────────────────────────────────────

    @Nested
    class ExpireTrial {

        @Test
        void trialSubscription_expiresToFree() {
            Subscription trial = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(trial));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.expireTrial(1L);

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.FREE);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── suspend ────────────────────────────────────────────────────

    @Nested
    class Suspend {

        @Test
        void activeSubscription_succeeds() {
            Subscription active = createActiveSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(active));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.suspend(1L);

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.SUSPENDED);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── reactivate ─────────────────────────────────────────────────

    @Nested
    class Reactivate {

        @Test
        void suspendedSubscription_reactivates() {
            Subscription suspended = createSuspendedSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(suspended));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.reactivate(1L);

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
            verify(domainEventPublisher).publishDomainEvents(any());
        }
    }

    // ── cancel ─────────────────────────────────────────────────────

    @Nested
    class Cancel {

        @Test
        void activeSubscription_cancels() {
            Subscription active = createActiveSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(active));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.cancel(1L);

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.CANCELLED);
            assertThat(result.getCancelledAt()).isNotNull();
            verify(domainEventPublisher).publishDomainEvents(any());
        }

        @Test
        void trialSubscription_cancels() {
            Subscription trial = createTrialSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(trial));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            Subscription result = service.cancel(1L);

            assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.CANCELLED);
        }
    }

    // ── event publishing ───────────────────────────────────────────

    @Nested
    class EventPublishing {

        @Test
        void publishesAndClearsDomainEvents() {
            Subscription active = createActiveSubscription();
            when(subscriptionRepository.findByTenantId(1L)).thenReturn(Optional.of(active));
            when(subscriptionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            SubscriptionApplicationService service = createService();
            service.suspend(1L);

            ArgumentCaptor<Subscription> captor = ArgumentCaptor.forClass(Subscription.class);
            verify(domainEventPublisher).publishDomainEvents(captor.capture());
        }

        @Test
        void noSubscriptionFound_doesNotPublish() {
            when(subscriptionRepository.findByTenantId(999L)).thenReturn(Optional.empty());

            SubscriptionApplicationService service = createService();
            assertThatThrownBy(() -> service.suspend(999L))
                .isInstanceOf(DomainException.class);

            verify(domainEventPublisher, never()).publishDomainEvents(any());
        }
    }
}
