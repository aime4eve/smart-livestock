package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.RumenMotilityLog;
import com.smartlivestock.shared.domain.TelemetryPage;

import java.time.Instant;
import java.util.Optional;
import java.util.List;

public interface RumenMotilityLogRepository {
    List<RumenMotilityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    TelemetryPage<RumenMotilityLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize);
    /** Paged batch read across livestock for full-farm export (NIX-325). */
    TelemetryPage<RumenMotilityLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable);
    TelemetryPage<RumenMotilityLog> findPageByDevice(Long deviceId, Instant from, Instant to, int page, int pageSize);
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
