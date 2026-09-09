package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.RumenMotilityLog;

import java.time.Instant;
import java.util.Optional;
import java.util.List;

public interface RumenMotilityLogRepository {
    List<RumenMotilityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    List<RumenMotilityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    List<RumenMotilityLog> findByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to);

    /**
     * Latest log of the device carrying a raw cumulative counter value.
     * Used to derive counter deltas and per-minute frequency for
     * cumulative-counter sources (firmware reports an accumulated count,
     * not a rate).
     */
    Optional<RumenMotilityLog> findLatestByDeviceIdWithRawCounter(Long deviceId);
    RumenMotilityLog save(RumenMotilityLog log);
}
