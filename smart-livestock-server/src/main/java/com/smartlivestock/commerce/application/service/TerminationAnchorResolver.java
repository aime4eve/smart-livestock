package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Subscription;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Optional;

/**
 * Single source of truth for "when did this subscription terminate" — the
 * wall-clock decision shared by the export policy (NIX-325), the tenant
 * subscription health block (NIX-324) and admin overview.
 *
 * Statuses whose wall clock has passed count as terminated even when nobody
 * flipped the status column (nothing auto-flips it). RENEWAL_FAILED and
 * SUSPENDED are never terminated (revivable). TRIAL/FREE share the
 * trial-ends anchor: expireTrial() relabels TRIAL to FREE but keeps the
 * column (NIX-324 review, grantTrial resets tier — 8f2d45a0).
 */
@Component
public class TerminationAnchorResolver {

    /** Anchor instant plus whether the row's stored status already says it. */
    public record Termination(Instant anchoredAt) {}

    public Optional<Termination> resolve(Subscription sub, Instant now) {
        Optional<Instant> anchor = switch (sub.getStatus()) {
            case EXPIRED -> Optional.ofNullable(firstNonNull(sub.getExpiresAt(), sub.getCancelledAt(), now));
            case CANCELLED -> Optional.ofNullable(firstNonNull(sub.getCancelledAt(), null, now));
            case ACTIVE -> Optional.ofNullable(sub.getExpiresAt()).filter(now::isAfter);
            case TRIAL, FREE -> Optional.ofNullable(sub.getTrialEndsAt()).filter(now::isAfter);
            default -> Optional.empty(); // SUSPENDED / RENEWAL_FAILED: revivable
        };
        return anchor.map(Termination::new);
    }

    private static Instant firstNonNull(Instant a, Instant b, Instant c) {
        if (a != null) return a;
        if (b != null) return b;
        return c;
    }
}
