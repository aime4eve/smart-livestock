package com.smartlivestock.commerce.infrastructure.acl;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.DomainEventPublisher;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

/**
 * Commerce-side adapter implementing the licensing-owned
 * {@link LicenseSubscriptionPort} (design §10, NIX-184).
 * <p>
 * All state changes go through {@link Subscription} domain methods so the
 * aggregate's invariants and domain events stay intact; events are published
 * after save, matching {@code SubscriptionApplicationService}'s pattern.
 */
@Component
@RequiredArgsConstructor
public class CommerceLicenseAdapter implements LicenseSubscriptionPort {

    /** Default billing model for trials created through licensing flows. */
    private static final String DEFAULT_BILLING_MODEL = "direct";

    /** Fallback billing cycle when the subscription has none yet. */
    private static final String DEFAULT_BILLING_CYCLE = "monthly";

    private final SubscriptionRepository subscriptionRepository;
    private final DomainEventPublisher domainEventPublisher;

    @Override
    @Transactional(readOnly = true)
    public Optional<LicenseSubscriptionSnapshot> findSubscription(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
            .map(sub -> new LicenseSubscriptionSnapshot(
                sub.getStatus() != null ? sub.getStatus().name() : null,
                sub.getTrialEndsAt(),
                sub.isTrialActive()));
    }

    @Override
    @Transactional
    public void applyTrialLicense(Long tenantId, Instant trialEndsAt) {
        Subscription sub = subscriptionRepository.findByTenantId(tenantId).orElse(null);
        if (sub == null) {
            Subscription created = Subscription.startTrial(
                tenantId, DEFAULT_BILLING_MODEL, Instant.now(), trialEndsAt);
            Subscription saved = subscriptionRepository.save(created);
            domainEventPublisher.publishDomainEvents(saved);
            return;
        }
        sub.extendTrial(trialEndsAt);
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
    }

    @Override
    @Transactional
    public void applyActiveLicense(Long tenantId, String tier, Instant expiresAt) {
        Subscription sub = loadSubscription(tenantId);
        SubscriptionTier targetTier = parseTier(tier);
        String resolvedCycle = sub.getBillingCycle() != null && !sub.getBillingCycle().isBlank()
            ? sub.getBillingCycle() : DEFAULT_BILLING_CYCLE;
        // TRIAL/FREE -> ACTIVE; ACTIVE keeps ACTIVE with the new tier.
        // SUSPENDED and other states are rejected by the domain guard.
        sub.changeTier(targetTier, resolvedCycle, expiresAt);
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
    }

    @Override
    @Transactional
    public void downgradeForLicense(Long tenantId) {
        Subscription sub = loadSubscription(tenantId);
        // ACTIVE / TRIAL / RENEWAL_FAILED -> FREE; FREE is idempotent (T4).
        sub.downgradeToFree();
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
    }

    @Override
    @Transactional
    public void suspendForLicense(Long tenantId, String reason) {
        Subscription sub = loadSubscription(tenantId);
        SubscriptionStatus status = sub.getStatus();
        if (status == SubscriptionStatus.ACTIVE) {
            sub.suspend();
        } else if (status != SubscriptionStatus.SUSPENDED) {
            // SUSPENDED: already suspended, idempotent no-op.
            throw new DomainException(ErrorCode.STATE_CONFLICT,
                "Cannot suspendForLicense: current status is " + status
                    + (reason != null ? " (reason: " + reason + ")" : ""));
        }
        Subscription saved = subscriptionRepository.save(sub);
        domainEventPublisher.publishDomainEvents(saved);
    }

    private Subscription loadSubscription(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new DomainException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                "Subscription not found for tenant: " + tenantId));
    }

    private SubscriptionTier parseTier(String tier) {
        if (tier == null || tier.isBlank()) {
            throw new DomainException(ErrorCode.VALIDATION_ERROR, "Tier must not be blank");
        }
        try {
            return SubscriptionTier.valueOf(tier.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new DomainException(ErrorCode.VALIDATION_ERROR, "Unsupported subscription tier: " + tier);
        }
    }
}
