package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.Subscription;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

/**
 * NIX-324 subscription-health verdict, per spec §2 matrix (ordered, first
 * match wins). Pure wall-clock logic — no repository access; the caller
 * enriches with the NIX-325 export window (identity side).
 *
 * Rendering contract for consumers: the banner type comes from
 * {@link HealthStatus}; the export-entitlement card renders whenever the
 * caller-supplied export window exists (CANCELLED/EXPIRED inside the 30-day
 * window both get it — the channel belongs to TerminationAnchorResolver,
 * not to the banner label).
 */
@Component
@RequiredArgsConstructor
public class SubscriptionHealthEvaluator {

    /** Days-before-expiry tiers for the escalating banner (spec §3). */
    public static final int WARN_LEVEL_DAYS = 14;

    public enum HealthStatus {
        TRIAL, RENEWAL_FAILED, SUSPENDED, CANCELLED, EXPIRED, EXPIRING_SOON, HEALTHY
    }

    public record HealthVerdict(
            HealthStatus healthStatus,
            Integer level,          // EXPIRING_SOON only: 14 / 7 / 3 bucket
            boolean trialActive,    // wall clock, never the bare status column
            String effectiveTier,   // degraded tier when terminated
            Long daysToExpiry,      // anchor-based whole days, null when no anchor
            boolean degraded,       // termination in effect (basic fallback)
            Instant terminatedAt    // non-null when degraded
    ) {}

    private final TerminationAnchorResolver terminationAnchorResolver;

    public HealthVerdict evaluate(Subscription sub, Instant now) {
        boolean trialActive = sub.isTrialActive();
        String degradedTier = "basic";
        String activeTier = sub.effectiveTier().name().toLowerCase();

        // Matrix #1: active trial.
        if (trialActive) {
            return new HealthVerdict(HealthStatus.TRIAL, levelFor(daysUntil(sub.getTrialEndsAt(), now)),
                    true, activeTier, daysUntil(sub.getTrialEndsAt(), now), false, null);
        }
        // Matrix #2–#4: explicit revivable/stopped statuses (banners differ,
        // none is "degraded" — RENEWAL_FAILED keeps tier until repayment,
        // SUSPENDED/CANCELLED are operator decisions).
        switch (sub.getStatus()) {
            case RENEWAL_FAILED -> {
                return new HealthVerdict(HealthStatus.RENEWAL_FAILED, null, false,
                        activeTier, daysUntil(sub.getExpiresAt(), now), false, null);
            }
            case SUSPENDED -> {
                return new HealthVerdict(HealthStatus.SUSPENDED, null, false,
                        activeTier, null, false, null);
            }
            case CANCELLED -> {
                var termination = terminationAnchorResolver.resolve(sub, now);
                // Cancelled = stopped; the export window (caller side) still
                // applies from cancelledAt.
                return new HealthVerdict(HealthStatus.CANCELLED, null, false,
                        degradedTier, null, true,
                        termination.map(TerminationAnchorResolver.Termination::anchoredAt).orElse(null));
            }
            default -> { /* fall through to wall-clock matrix below */ }
        }
        // Matrix #5: terminated by wall clock (EXPIRED status, or a passed
        // expires/trial column on any other status).
        var termination = terminationAnchorResolver.resolve(sub, now);
        if (termination.isPresent()) {
            Instant anchoredAt = termination.get().anchoredAt();
            return new HealthVerdict(HealthStatus.EXPIRED, null, false,
                    degradedTier, daysUntil(anchoredAt, now), true, anchoredAt);
        }
        // Matrix #6: expiring soon (ACTIVE anchored on expiresAt).
        Long days = daysUntil(sub.getExpiresAt(), now);
        if (days != null && days >= 0 && days <= WARN_LEVEL_DAYS) {
            return new HealthVerdict(HealthStatus.EXPIRING_SOON, levelFor(days), false,
                    activeTier, days, false, null);
        }
        // Matrix #7: healthy.
        return new HealthVerdict(HealthStatus.HEALTHY, null, false, activeTier, days, false, null);
    }

    private static Long daysUntil(Instant target, Instant now) {
        if (target == null) return null;
        return Duration.between(now, target).toDays();
    }

    private static Integer levelFor(Long days) {
        if (days == null) return null;
        if (days > 7) return 14;
        if (days > 3) return 7;
        return 3;
    }
}
