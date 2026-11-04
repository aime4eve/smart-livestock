package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.shared.domain.TelemetryPage;

import java.time.Instant;
import java.util.List;

public interface ActivityLogRepository {
    List<ActivityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);

    /**
     * Activity logs of one livestock recorded in the half-open window
     * {@code [from, to)} — the event-time window of the individual baseline
     * learning (plan 2026-11-03 §1.1). Half-open on purpose: a sample at
     * {@code to} belongs to the next window, not this one.
     */
    List<ActivityLog> findWindowByLivestockId(Long livestockId, Instant from, Instant to);
    TelemetryPage<ActivityLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize);
    /** Paged batch read across livestock for full-farm export (NIX-325). */
    TelemetryPage<ActivityLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable);
    List<ActivityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    ActivityLog save(ActivityLog log);
}
