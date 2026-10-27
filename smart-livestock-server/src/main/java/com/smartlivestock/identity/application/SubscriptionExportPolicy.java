package com.smartlivestock.identity.application;

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
 * Terminated states: EXPIRED (anchor expiresAt), CANCELLED (anchor
 * cancelledAt), an ACTIVE whose expiresAt has passed, and TRIAL/FREE whose
 * trial end has passed (FREE is expireTrial()'s label for a lapsed trial and
 * keeps trial_ends_at — both labels anchor on it). Nothing auto-flips the
 * status column, so the wall clock decides. RENEWAL_FAILED is deliberately
 * excluded (repayment can revive it); SUSPENDED likewise. Window:
 * termination instant + windowDays (default 30, GDPR Art. 12(3) one-month
 * response standard, user ruling).
 */
@Component
public class SubscriptionExportPolicy {

    private final SubscriptionRepository subscriptionRepository;
    private final long windowDays;

    public SubscriptionExportPolicy(SubscriptionRepository subscriptionRepository,
                                    @Value("${smartlivestock.export.window-days:30}") long windowDays) {
        this.subscriptionRepository = subscriptionRepository;
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
        Subscription sub = subOpt.get();

        Optional<Instant> terminatedAtOpt = switch (sub.getStatus()) {
            case EXPIRED -> Optional.of(firstNonNull(sub.getExpiresAt(), now));
            case CANCELLED -> Optional.of(firstNonNull(sub.getCancelledAt(), now));
            case ACTIVE -> Optional.of(sub.getExpiresAt())
                    .filter(end -> now.isAfter(end));
            // TRIAL lapsed in place, or flipped to FREE via expireTrial() —
            // same fact, two labels: expireTrial keeps trial_ends_at, so both
            // anchor on it (NIX-324 review: excluding FREE made the export
            // right depend on whether an admin happened to flip the status).
            case TRIAL, FREE -> Optional.of(sub.getTrialEndsAt())
                    .filter(end -> now.isAfter(end));
            default -> Optional.empty(); // SUSPENDED / RENEWAL_FAILED: no channel
        };

        if (terminatedAtOpt.isEmpty()) {
            return Decision.denied(DenialReason.NOT_TERMINATED);
        }
        Instant terminatedAt = terminatedAtOpt.get();
        Instant windowEndsAt = terminatedAt.plusSeconds(windowDays * 24 * 3600);
        if (!now.isBefore(windowEndsAt)) {
            return Decision.denied(DenialReason.WINDOW_CLOSED);
        }
        return Decision.eligible(new Eligibility(terminatedAt, windowEndsAt));
    }

    private static Instant firstNonNull(Instant a, Instant b) {
        return a != null ? a : b;
    }
}
