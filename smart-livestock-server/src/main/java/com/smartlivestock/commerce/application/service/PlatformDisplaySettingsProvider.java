package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
import com.smartlivestock.commerce.domain.repository.PlatformDisplaySettingsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Read-side access to the NIX-389 locked-tile presentation policy with a
 * short TTL cache: the policy is consulted on the ranch overview hot path
 * (30s polling), so each request must not hit the database.
 * {@link #invalidate()} is called after a successful PUT so the new policy
 * takes effect immediately.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class PlatformDisplaySettingsProvider {

    private static final long CACHE_TTL_SECONDS = 60;

    private final PlatformDisplaySettingsRepository settingsRepository;

    private final AtomicReference<CachedPolicy> cache = new AtomicReference<>();

    /** Current policy: cached up to 60s, DB read on expiry, SHOW_LOCKED as fallback. */
    public LockedTilePolicy current() {
        CachedPolicy cached = cache.get();
        Instant now = Instant.now();
        if (cached != null && now.isBefore(cached.expiresAt)) {
            return cached.policy;
        }
        LockedTilePolicy fresh = loadFromDatabase();
        cache.set(new CachedPolicy(fresh, now.plusSeconds(CACHE_TTL_SECONDS)));
        return fresh;
    }

    /** Drop the cache so the next {@link #current()} reads the persisted row. */
    public void invalidate() {
        cache.set(null);
    }

    private LockedTilePolicy loadFromDatabase() {
        try {
            return settingsRepository.findFirst()
                    .map(settings -> settings.getLockedTilePolicy() == null
                            ? LockedTilePolicy.SHOW_LOCKED
                            : settings.getLockedTilePolicy())
                    .orElseGet(() -> {
                        // The V20261107100000 seed guarantees a row; fall back to
                        // SHOW_LOCKED if it is ever missing so tiles degrade to
                        // the pre-change visible behaviour instead of vanishing.
                        log.warn("platform_display_settings row missing, falling back to SHOW_LOCKED");
                        return LockedTilePolicy.SHOW_LOCKED;
                    });
        } catch (Exception e) {
            // A settings-read outage must never take the overview down:
            // degrade to the default policy (tiles visible, lock affordance on).
            log.warn("platform_display_settings read failed, falling back to SHOW_LOCKED: {}", e.getMessage());
            return LockedTilePolicy.SHOW_LOCKED;
        }
    }

    private record CachedPolicy(LockedTilePolicy policy, Instant expiresAt) {}
}
