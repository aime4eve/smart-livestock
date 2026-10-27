package com.smartlivestock.identity.application;

import com.smartlivestock.commerce.application.service.TerminationAnchorResolver;
import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;

/**
 * Decides whether a tenant may use the expired-tenant data export channel
 * (NIX-325, GDPR window ruling 2026-10-26).
 *
 * Termination semantics live in {@link TerminationAnchorResolver} (single
 * source of truth shared with the NIX-324 health evaluator): EXPIRED anchors
 * expiresAt, CANCELLED anchors cancelledAt, a passed wall-clock column counts
 * even when nobody flipped the status; RENEWAL_FAILED and SUSPENDED are
 * revivable and get no channel. Window: termination instant + windowDays
 * (default 30, GDPR Art. 12(3) one-month response standard, user ruling).
 */
@Component
public class SubscriptionExportPolicy {

    private final SubscriptionRepository subscriptionRepository;
    private final TerminationAnchorResolver terminationAnchorResolver;
    private final long windowDays;

    public SubscriptionExportPolicy(SubscriptionRepository subscriptionRepository,
                                    TerminationAnchorResolver terminationAnchorResolver,
                                    @Value("${smartlivestock.export.window-days:30}") long windowDays) {
        this.subscriptionRepository = subscriptionRepository;
        this.terminationAnchorResolver = terminationAnchorResolver;
        this.windowDays = windowDays;
    }

    public record Eligibility(Instant terminatedAt, Instant windowEndsAt) {}

    public enum DenialReason { NOT_TERMINATED, WINDOW_CLOSED, NO_SUBSCRIPTION }

    public record Decision(Eligibility eligibility, DenialReason denialReason) {

        public static Decision eligible(Eligibility e) { return new Decision(e, null); }
        public static Decision denied(DenialReason r) { return new Decision(null, r); }
        public boolean isEligible() { return eligibility != null; }
    }

    public Decision assess(Long tenantId, Instant now) {
        Optional<Subscription> subOpt = subscriptionRepository.findByTenantId(tenantId);
        if (subOpt.isEmpty()) {
            return Decision.denied(DenialReason.NO_SUBSCRIPTION);
        }
        return terminationAnchorResolver.resolve(subOpt.get(), now)
                .map(termination -> {
                    Instant terminatedAt = termination.anchoredAt();
                    Instant windowEndsAt = terminatedAt.plusSeconds(windowDays * 24 * 3600);
                    if (!now.isBefore(windowEndsAt)) {
                        return Decision.denied(DenialReason.WINDOW_CLOSED);
                    }
                    return Decision.eligible(new Eligibility(terminatedAt, windowEndsAt));
                })
                .orElseGet(() -> Decision.denied(DenialReason.NOT_TERMINATED));
    }
}
