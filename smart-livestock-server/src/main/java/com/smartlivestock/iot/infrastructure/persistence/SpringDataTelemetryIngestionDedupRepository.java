package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.TelemetryIngestionDedupJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SpringDataTelemetryIngestionDedupRepository
        extends JpaRepository<TelemetryIngestionDedupJpaEntity, Long> {

    Optional<TelemetryIngestionDedupJpaEntity> findByProviderAndExternalDeviceIdAndProviderEventTsAndChannel(
            String provider, String externalDeviceId, long providerEventTs, String channel);

    List<TelemetryIngestionDedupJpaEntity> findByDeviceIdAndCanonical(long deviceId, boolean canonical);

    Optional<TelemetryIngestionDedupJpaEntity> findByCanonicalKeyAndCanonical(String canonicalKey, boolean canonical);

    /**
     * Transaction-scoped advisory lock serializing the arbitration for one
     * source observation and one device's canonical space (parking V88
     * pattern); released automatically at transaction end.
     */
    @Query(value = "SELECT pg_advisory_xact_lock(hashtext(:lockKey))", nativeQuery = true)
    void acquireAdvisoryLock(@Param("lockKey") String lockKey);
}
