package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsProvider.HealthThresholds;
import com.smartlivestock.commerce.domain.model.Subscription;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;

/**
 * NIX-324 subscription-health verdict, per spec §2 matrix (ordered, first
 * match wins). Wall-clock logic plus the platform-configurable banner tiers
 * (V20261103100000); the caller enriches with the NIX-325 export window
 * (identity side).
 *
 * Rendering contract for consumers: the banner type comes from
 * {@link HealthStatus}; the export-entitlement card renders whenever the
 * caller-supplied export window exists (CANCELLED/EXPIRED inside the 30-day
 * window both get it — the channel belongs to TerminationAnchorResolver,
 * not to the banner label). The "remind me later" button is driven by
 * {@code snoozeAllowed} — computed here so the frontend never hardcodes
 * tier numbers (the tiers are platform-configurable since V20261103100000).
 */
@Component
@RequiredArgsConstructor
public class SubscriptionHealthEvaluator {

    public enum HealthStatus {
        TRIAL, RENEWAL_FAILED, SUSPENDED, CANCELLED, EXPIRED, EXPIRING_SOON, HEALTHY
    }

    public record HealthVerdict(
            HealthStatus healthStatus,
            Integer level,          // EXPIRING_SOON only: configurable tier bucket
            boolean trialActive,    // wall clock, never the bare status column
            String effectiveTier,   // degraded tier when terminated
            Long daysToExpiry,      // anchor-based whole days, null when no anchor
            boolean degraded,       // termination in effect (basic fallback)
            Instant terminatedAt,   // non-null when degraded
            Boolean snoozeAllowed   // EXPIRING_SOON only: level above the danger tier
    ) {
        /** Back-compat shim for callers/tests that predate snoozeAllowed. */
        public HealthVerdict(HealthStatus healthStatus, Integer level, boolean trialActive,
                             String effectiveTier, Long daysToExpiry, boolean degraded,
                             Instant terminatedAt) {
            this(healthStatus, level, trialActive, effectiveTier, daysToExpiry,
                    degraded, terminatedAt, null);
        }
    }

    private final TerminationAnchorResolver terminationAnchorResolver;
    private final SubscriptionHealthSettingsProvider settingsProvider;

    public HealthVerdict evaluate(Subscription sub, Instant now) {
        HealthThresholds thresholds = settingsProvider.current();
        boolean trialActive = sub.isTrialActive();
        String degradedTier = "basic";
        String activeTier = sub.effectiveTier().name().toLowerCase();

        // Matrix #1: active trial. Trial banner is its own type — the snooze
        // gate stays null (snooze is an EXPIRING_SOON-only affordance).
        if (trialActive) {
            Integer level = levelFor(daysUntil(sub.getTrialEndsAt(), now), thresholds);
            return new HealthVerdict(HealthStatus.TRIAL, level,
                    true, activeTier, daysUntil(sub.getTrialEndsAt(), now), false, null,
                    null);
        }
        // Matrix #2–#4: explicit revivable/stopped statuses (banners differ,
        // none is "degraded" — RENEWAL_FAILED keeps tier until repayment,
        // SUSPENDED/CANCELLED are operator decisions).
        switch (sub.getStatus()) {
            case RENEWAL_FAILED -> {
                return new HealthVerdict(HealthStatus.RENEWAL_FAILED, null, false,
                        activeTier, daysUntil(sub.getExpiresAt(), now), false, null,
                        null);
            }
            case SUSPENDED -> {
                return new HealthVerdict(HealthStatus.SUSPENDED, null, false,
                        activeTier, null, false, null, null);
            }
            case CANCELLED -> {
                var termination = terminationAnchorResolver.resolve(sub, now);
                // Cancelled = stopped; the export window (caller side) still
                // applies from cancelledAt.
                return new HealthVerdict(HealthStatus.CANCELLED, null, false,
                        degradedTier, null, true,
                        termination.map(TerminationAnchorResolver.Termination::anchoredAt).orElse(null),
                        null);
            }
            default -> { /* fall through to wall-clock matrix below */ }
        }
        // Matrix #5: terminated by wall clock (EXPIRED status, or a passed
        // expires/trial column on any other status).
        var termination = terminationAnchorResolver.resolve(sub, now);
        if (termination.isPresent()) {
            Instant anchoredAt = termination.get().anchoredAt();
            return new HealthVerdict(HealthStatus.EXPIRED, null, false,
                    degradedTier, daysUntil(anchoredAt, now), true, anchoredAt, null);
        }
        // Matrix #6: expiring soon (ACTIVE anchored on expiresAt).
        Long days = daysUntil(sub.getExpiresAt(), now);
        if (days != null && days >= 0 && days <= thresholds.warnDays()) {
            Integer level = levelFor(days, thresholds);
            return new HealthVerdict(HealthStatus.EXPIRING_SOON, level, false,
                    activeTier, days, false, null,
                    snoozeAllowedFor(level, thresholds));
        }
        // Matrix #7: healthy.
        return new HealthVerdict(HealthStatus.HEALTHY, null, false, activeTier, days, false, null, null);
    }

    private static Long daysUntil(Instant target, Instant now) {
        if (target == null) return null;
        return Duration.between(now, target).toDays();
    }

    private static Integer levelFor(Long days, HealthThresholds thresholds) {
        if (days == null) return null;
        if (days > thresholds.cautionDays()) return thresholds.warnDays();
        if (days > thresholds.dangerDays()) return thresholds.cautionDays();
        return thresholds.dangerDays();
    }

    private static Boolean snoozeAllowedFor(Integer level, HealthThresholds thresholds) {
        if (level == null) return null;
        return level > thresholds.dangerDays();
    }
}
