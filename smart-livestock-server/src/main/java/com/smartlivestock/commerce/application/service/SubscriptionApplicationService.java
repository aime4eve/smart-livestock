package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import org.springframework.stereotype.Service;

import java.time.Instant;

/**
 * Application service handling subscription write operations.
 * <p>
 * Pattern: load aggregate → call domain method → save → publish events → clear.
 */
@Service
public class SubscriptionApplicationService {

    private final SubscriptionRepository subscriptionRepository;
    private final DomainEventPublisher domainEventPublisher;

    public SubscriptionApplicationService(SubscriptionRepository subscriptionRepository,
                                          DomainEventPublisher domainEventPublisher) {
        this.subscriptionRepository = subscriptionRepository;
        this.domainEventPublisher = domainEventPublisher;
    }

    /**
     * Get existing subscription or create a new trial for the tenant.
     */
    public Subscription getOrCreateSubscription(Long tenantId, String billingModel) {
        return subscriptionRepository.findByTenantId(tenantId)
            .orElseGet(() -> {
                Instant now = Instant.now();
                Instant trialEnd = now.plusSeconds(14 * 86400);
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
        String resolvedCycle = billingCycle != null ? billingCycle : sub.getBillingCycle();
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
