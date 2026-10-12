package com.smartlivestock.identity.application;

import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Resolves the timezone for timezone-dependent concerns (chart day/hour
 * buckets, local-midnight conversions, Blade X-TimeZone) via the priority
 * chain (ruling 2026-10-12):
 * <pre>
 *   farm timezone → tenant timezone → platform default timezone
 * </pre>
 * The platform default comes from {@code smartlivestock.timezone.default}
 * (env {@code SMARTLIVESTOCK_DEFAULT_TIMEZONE}); when unset, a request that
 * carries the client's device offset keeps the pre-tenant behavior (offset
 * wins), and finally plain UTC. Storage stays UTC everywhere — this chain is
 * presentation/boundary only. Cached in-process; evicted on updates.
 */
@Service
public class TenantZoneResolver {

    private final SpringDataTenantRepository tenantRepository;
    private final SpringDataFarmRepository farmRepository;
    private final String platformDefaultRaw;

    private final Map<Long, Optional<ZoneId>> tenantZoneCache = new ConcurrentHashMap<>();
    private final Map<Long, Long> farmTenantCache = new ConcurrentHashMap<>();
    private final Map<Long, Optional<ZoneId>> farmZoneCache = new ConcurrentHashMap<>();

    public TenantZoneResolver(SpringDataTenantRepository tenantRepository,
                              SpringDataFarmRepository farmRepository,
                              @Value("${smartlivestock.timezone.default:}") String platformDefaultRaw) {
        this.tenantRepository = tenantRepository;
        this.farmRepository = farmRepository;
        this.platformDefaultRaw = platformDefaultRaw;
    }

    /** Explicitly configured zone (farm column first, then tenant column); empty = nothing set. */
    public Optional<ZoneId> explicitZoneForFarm(Long farmId) {
        if (farmId == null) return Optional.empty();
        Optional<ZoneId> farmZone = farmZoneCache.computeIfAbsent(farmId, id ->
                farmRepository.findById(id)
                        .map(f -> parseOrNull(f.getTimezone()))
                        .orElse(Optional.empty()));
        if (farmZone.isPresent()) return farmZone;
        Long tenantId = farmTenantCache.computeIfAbsent(farmId, id ->
                farmRepository.findById(id).map(f -> f.getTenantId()).orElse(null));
        return explicitZoneForTenant(tenantId);
    }

    /** Explicitly configured tenant zone; empty = not set. */
    public Optional<ZoneId> explicitZoneForTenant(Long tenantId) {
        if (tenantId == null) return Optional.empty();
        return tenantZoneCache.computeIfAbsent(tenantId, id ->
                tenantRepository.findById(id)
                        .map(t -> parseOrNull(t.getTimezone()))
                        .orElse(Optional.empty()));
    }

    /**
     * Full chain for request-scoped grouping: farm → tenant → platform default
     * (when configured) → client device offset (pre-tenant behavior) → UTC.
     */
    public ZoneId zoneForFarm(Long farmId, Integer clientOffsetMinutes) {
        Optional<ZoneId> explicit = explicitZoneForFarm(farmId);
        if (explicit.isPresent()) return explicit.get();
        return fallbackZone(clientOffsetMinutes);
    }

    /** Chain for tenant-scoped resolution (no farm context). */
    public ZoneId zoneForTenant(Long tenantId, Integer clientOffsetMinutes) {
        Optional<ZoneId> explicit = explicitZoneForTenant(tenantId);
        if (explicit.isPresent()) return explicit.get();
        return fallbackZone(clientOffsetMinutes);
    }

    /** Chain with no request context (pilot local-date conversion, X-TimeZone): explicit → platform default → UTC. Never null. */
    public ZoneId zoneForTenantStrict(Long tenantId) {
        return explicitZoneForTenant(tenantId)
                .orElseGet(() -> parseOrNull(platformDefaultRaw).orElse(ZoneOffset.UTC));
    }

    /** Presentation offset for admin surfaces; follows the strict chain (DST-aware, at now). */
    public int utcOffsetMinutes(Long tenantId) {
        return zoneForTenantStrict(tenantId).getRules().getOffset(Instant.now()).getTotalSeconds() / 60;
    }

    private ZoneId fallbackZone(Integer clientOffsetMinutes) {
        ZoneId platformDefault = platformDefaultZone();
        if (platformDefault != null) return platformDefault;
        if (clientOffsetMinutes != null) {
            return ZoneOffset.ofTotalSeconds(clientOffsetMinutes * 60);
        }
        return ZoneOffset.UTC;
    }

    /** Configured platform default, or null when the property is unset/invalid. */
    private ZoneId platformDefaultZone() {
        return parseOrNull(platformDefaultRaw).orElse(null);
    }

    private static Optional<ZoneId> parseOrNull(String raw) {
        if (raw == null || raw.isBlank()) return Optional.empty();
        try {
            return Optional.of(ZoneId.of(raw.trim()));
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    public void evictTenant(Long tenantId) {
        if (tenantId == null) return;
        tenantZoneCache.remove(tenantId);
    }

    public void evictFarm(Long farmId) {
        if (farmId == null) return;
        farmZoneCache.remove(farmId);
    }
}
