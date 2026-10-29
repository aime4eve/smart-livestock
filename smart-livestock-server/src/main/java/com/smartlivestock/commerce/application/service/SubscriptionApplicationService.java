package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.shared.common.ConfiguredTrialEnds;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;

/**
 * Application service handling subscription write operations.
 * <p>
 * Pattern: load aggregate → call domain method → save → publish events → clear.
 */
@Service
public class SubscriptionApplicationService {

    private static final long SELF_SERVICE_TRIAL_DAYS = 14;

    private final SubscriptionRepository subscriptionRepository;
    private final DomainEventPublisher domainEventPublisher;
    private final Optional<Instant> configuredTrialEndsAt;

    public SubscriptionApplicationService(SubscriptionRepository subscriptionRepository,
                                          DomainEventPublisher domainEventPublisher,
                                          @Value("${smartlivestock.trial.ends-at:}") String configuredTrialEndsAt) {
        this.subscriptionRepository = subscriptionRepository;
        this.domainEventPublisher = domainEventPublisher;
        this.configuredTrialEndsAt = ConfiguredTrialEnds.parse(configuredTrialEndsAt);
    }

    /**
     * Get existing subscription or create a new trial for the tenant.
     * <p>
     * Trial deadline (ruling 2026-10-12): when {@code smartlivestock.trial.ends-at}
     * is configured, self-service trials end at that shared campaign deadline
     * instead of the legacy rolling now+14d window.
     */
    public Subscription getOrCreateSubscription(Long tenantId, String billingModel) {
        return subscriptionRepository.findByTenantId(tenantId)
            .orElseGet(() -> {
                Instant now = Instant.now();
                Instant trialEnd = configuredTrialEndsAt
                        .orElseGet(() -> now.plusSeconds(SELF_SERVICE_TRIAL_DAYS * 86400));
                Subscription created = Subscription.startTrial(tenantId, billingModel, now, trialEnd);
                Subscription saved = subscriptionRepository.save(created);
                domainEventPublisher.publishDomainEvents(saved);
                return saved;
            });
    }

    /**
     * Upgrade subscription tier (from TRIAL → ACTIVE, or change tier on ACTIVE/FREE).
     */
    public Subscription upgrade(Long tenantId, SubscriptionTier newTier, String billingCycle) {
        Subscription sub = loadSubscription(tenantId);
        String resolvedCycle = billingCycle != null && !billingCycle.isBlank()
            ? billingCycle : sub.getBillingCycle();
        if (resolvedCycle == null || resolvedCycle.isBlank()) {
            resolvedCycle = "monthly";
        }
        Instant expiresAt = Instant.now().plusSeconds(cycleSeconds(resolvedCycle));
        sub.changeTier(newTier, resolvedCycle, expiresAt);
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Expire a trial subscription to FREE.
     */
    public Subscription expireTrial(Long tenantId) {
        Subscription sub = loadSubscription(tenantId);
        sub.expireTrial();
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Suspend an active subscription.
     */
    public Subscription suspend(Long tenantId) {
        Subscription sub = loadSubscription(tenantId);
        sub.suspend();
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Reactivate a suspended subscription.
     */
    public Subscription reactivate(Long tenantId) {
        Subscription sub = loadSubscription(tenantId);
        sub.reactivate();
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Admin-assisted repayment (NIX-334): RENEWAL_FAILED → ACTIVE with the
     * period extended one billing cycle from max(now, previous expiry), the
     * same arithmetic a successful renewal would apply.
     */
    public Subscription recoverRenewalFailure(Long tenantId) {
        Subscription sub = loadSubscription(tenantId);
        String cycle = sub.getBillingCycle();
        if (cycle == null || cycle.isBlank()) {
            cycle = "monthly";
        }
        Instant now = Instant.now();
        Instant base = sub.getExpiresAt() != null && sub.getExpiresAt().isAfter(now)
            ? sub.getExpiresAt() : now;
        sub.recoverFromRenewalFailure(base.plusSeconds(cycleSeconds(cycle)));
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    /**
     * Cancel an active or trial subscription.
     */
    public Subscription cancel(Long tenantId) {
        Subscription sub = loadSubscription(tenantId);
        sub.cancel(Instant.now());
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
        return saved;
    }

    // ── Helpers ────────────────────────────────────────────────────

    private Subscription loadSubscription(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new DomainException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                "Subscription not found for tenant: " + tenantId));
    }

    private long cycleSeconds(String billingCycle) {
        if ("yearly".equalsIgnoreCase(billingCycle)) {
            return 365L * 86400;
        }
        if ("monthly".equalsIgnoreCase(billingCycle)) {
            return 30L * 86400;
        }
        throw new DomainException(ErrorCode.INVALID_BILLING_MODEL,
            "Unsupported billing cycle: " + billingCycle);
    }
}
