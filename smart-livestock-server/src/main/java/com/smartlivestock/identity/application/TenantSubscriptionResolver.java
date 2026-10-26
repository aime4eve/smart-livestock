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
    private final Map<Long, CacheEntry> cache = new ConcurrentHashMap<>();

    public TenantSubscriptionResolver(SubscriptionRepository subscriptionRepository) {
        this.subscriptionRepository = subscriptionRepository;
    }

    public SubscriptionSnapshot resolve(Long tenantId) {
        if (tenantId == null) {
            return new SubscriptionSnapshot("NONE", DEGRADED_TIER, false, Instant.now());
        }
        CacheEntry entry = cache.get(tenantId);
        long now = System.currentTimeMillis();
        if (entry != null && now - entry.cachedAtMs() < TTL_MS) {
            return entry.snapshot();
        }
        SubscriptionSnapshot snapshot = doResolve(tenantId);
        cache.put(tenantId, new CacheEntry(snapshot, now));
        return snapshot;
    }

    private SubscriptionSnapshot doResolve(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
                .map(sub -> {
                    String status = sub.getStatus() != null ? sub.getStatus().name() : "UNKNOWN";
                    boolean trialActive = sub.isTrialActive();
                    String tier = sub.isActiveOrTrial()
                            ? sub.effectiveTier().name().toLowerCase()
                            : DEGRADED_TIER;
                    return new SubscriptionSnapshot(status, tier, trialActive, Instant.now());
                })
                .orElseGet(() -> new SubscriptionSnapshot("NONE", DEGRADED_TIER, false, Instant.now()));
    }

    public void evictTenant(Long tenantId) {
        if (tenantId != null) {
            cache.remove(tenantId);
        }
    }
}
