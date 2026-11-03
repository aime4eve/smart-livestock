package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionHealthSettingsRepository;
import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionHealthSettingsJpaEntity;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Read-side access to the configurable NIX-324 banner tiers with a short TTL
 * cache: the evaluator runs per subscription row on hot paths (GET
 * /subscription, admin overview pagination), so each verdict must not hit the
 * database. {@link #invalidate()} is called after a successful PUT so the new
 * thresholds take effect immediately.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class SubscriptionHealthSettingsProvider {

    /** Immutable threshold triple consumed by SubscriptionHealthEvaluator. */
    public record HealthThresholds(int warnDays, int cautionDays, int dangerDays) {

        /** Pre-change hardcoded behaviour (V20261103100000 seed row). */
        public static HealthThresholds defaults() {
            return new HealthThresholds(14, 7, 3);
        }
    }

    private static final long CACHE_TTL_SECONDS = 60;

    private final SpringDataSubscriptionHealthSettingsRepository settingsRepository;

    private final AtomicReference<CachedThresholds> cache = new AtomicReference<>();

    /** Current thresholds: cached up to 60s, DB read on expiry, defaults as fallback. */
    public HealthThresholds current() {
        CachedThresholds cached = cache.get();
        Instant now = Instant.now();
        if (cached != null && now.isBefore(cached.expiresAt)) {
            return cached.thresholds;
        }
        HealthThresholds fresh = loadFromDatabase();
        cache.set(new CachedThresholds(fresh, now.plusSeconds(CACHE_TTL_SECONDS)));
        return fresh;
    }

    /** Drop the cache so the next {@link #current()} reads the persisted row. */
    public void invalidate() {
        cache.set(null);
    }

    private HealthThresholds loadFromDatabase() {
        return settingsRepository.findFirstByOrderByIdAsc()
                .<HealthThresholds>map(entity -> new HealthThresholds(
                        entity.getWarnDays(), entity.getCautionDays(), entity.getDangerDays()))
                .orElseGet(() -> {
                    // The V20261103100000 seed guarantees a row; fall back to the
                    // pre-change hardcoded tiers if it is ever missing so the
                    // banner degrades to known behaviour instead of failing.
                    log.warn("subscription_health_settings row missing, falling back to defaults");
                    return HealthThresholds.defaults();
                });
    }

    private record CachedThresholds(HealthThresholds thresholds, Instant expiresAt) {}

    /** Test hook: replace cached content deterministically. */
    void putInCacheForTest(HealthThresholds thresholds) {
        cache.set(new CachedThresholds(thresholds, Instant.now().plusSeconds(CACHE_TTL_SECONDS)));
    }
}
