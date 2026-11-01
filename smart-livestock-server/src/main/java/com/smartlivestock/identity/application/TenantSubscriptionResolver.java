package com.smartlivestock.identity.application;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Resolves a tenant's subscription snapshot (status + effective tier) for
 * request-context enrichment, with a short in-process cache so the
 * ApiKeyAuthFilter path does not query the subscriptions table per request.
 *
 * Tier semantics follow HealthSubscriptionPortImpl (health ACL):
 * active/trial tenants get Subscription.effectiveTier() (active trials are
 * PREMIUM); anything else — EXPIRED / SUSPENDED / CANCELLED / FREE / no
 * subscription at all — degrades to "basic". This is the 2026-10-26 ruling
 * (NIX-323): degrade, don't reject.
 *
 * Cache: 60s TTL keeps an expired/degraded tenant from being served a stale
 * premium tier for long; subscription writes evict immediately (see
 * SubscriptionApplicationService). Modeled after TenantZoneResolver.
 */
@Component
public class TenantSubscriptionResolver {

    /** status is the raw subscription status (or NONE); tier is already degraded. */
    public record SubscriptionSnapshot(String status, String tier, boolean trialActive, Instant resolvedAt) {}

    private record CacheEntry(SubscriptionSnapshot snapshot, long cachedAtMs) {}

    private static final long TTL_MS = 60_000;
    private static final String DEGRADED_TIER = "basic";

    private final SubscriptionRepository subscriptionRepository;
    private final com.smartlivestock.commerce.application.service.TerminationAnchorResolver terminationAnchorResolver;
    private final Map<Long, CacheEntry> cache = new ConcurrentHashMap<>();

    public TenantSubscriptionResolver(SubscriptionRepository subscriptionRepository,
                                      com.smartlivestock.commerce.application.service.TerminationAnchorResolver terminationAnchorResolver) {
        this.subscriptionRepository = subscriptionRepository;
        this.terminationAnchorResolver = terminationAnchorResolver;
    }

    /** Production entry — wall clock, 60s cache read as before. */
    public SubscriptionSnapshot resolve(Long tenantId) {
        if (tenantId == null) {
            return new SubscriptionSnapshot("NONE", DEGRADED_TIER, false, Instant.now());
        }
        CacheEntry entry = cache.get(tenantId);
        long cacheMs = System.currentTimeMillis();
        if (entry != null && cacheMs - entry.cachedAtMs() < TTL_MS) {
            return entry.snapshot();
        }
        SubscriptionSnapshot snapshot = doResolve(tenantId, Instant.now());
        cache.put(tenantId, new CacheEntry(snapshot, cacheMs));
        return snapshot;
    }

    /**
     * Clock-injectable variant so cross-component checks (NIX-324
     * SubscriptionSemanticsCrossCheckTest) can align the resolver with the
     * evaluator and export policy on one shared Instant. Bypasses the 60s
     * cache read: with a fixed clock a cached wall-clock snapshot would be
     * meaningless. Still refreshes the cache for subsequent production reads.
     */
    public SubscriptionSnapshot resolve(Long tenantId, Instant now) {
        if (tenantId == null) {
            return new SubscriptionSnapshot("NONE", DEGRADED_TIER, false, now);
        }
        SubscriptionSnapshot snapshot = doResolve(tenantId, now);
        cache.put(tenantId, new CacheEntry(snapshot, System.currentTimeMillis()));
        return snapshot;
    }

    private SubscriptionSnapshot doResolve(Long tenantId, Instant now) {
        return subscriptionRepository.findByTenantId(tenantId)
                .map(sub -> {
                    String status = sub.getStatus() != null ? sub.getStatus().name() : "UNKNOWN";
                    boolean trialActive = sub.isTrialActive();
                    // Termination by wall clock (TerminationAnchorResolver, the
                    // single source shared with the NIX-324 evaluator and the
                    // NIX-325 export policy) degrades to basic even while the
                    // status column still says ACTIVE/TRIAL — the "lapsed but
                    // never flipped" case must not keep a paid window.
                    // Revivable states (RENEWAL_FAILED/SUSPENDED) keep the
                    // paid tier as a repayment grace.
                    boolean terminated = terminationAnchorResolver
                            .resolve(sub, now).isPresent();
                    boolean keepsTier = !terminated
                            && (sub.isActiveOrTrial()
                                || sub.getStatus() == com.smartlivestock.commerce.domain.model.SubscriptionStatus.RENEWAL_FAILED
                                || sub.getStatus() == com.smartlivestock.commerce.domain.model.SubscriptionStatus.SUSPENDED);
                    String tier = keepsTier
                            ? sub.effectiveTier().name().toLowerCase()
                            : DEGRADED_TIER;
                    return new SubscriptionSnapshot(status, tier, trialActive, now);
                })
                .orElseGet(() -> new SubscriptionSnapshot("NONE", DEGRADED_TIER, false, now));
    }

    public void evictTenant(Long tenantId) {
        if (tenantId != null) {
            cache.remove(tenantId);
        }
    }
}
