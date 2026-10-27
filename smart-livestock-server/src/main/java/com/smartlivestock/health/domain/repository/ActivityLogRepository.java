package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.shared.domain.TelemetryPage;

import java.time.Instant;
import java.util.List;

public interface ActivityLogRepository {
    List<ActivityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    TelemetryPage<ActivityLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize);
    /** Paged batch read across livestock for full-farm export (NIX-325). */
    TelemetryPage<ActivityLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable);
    List<ActivityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    ActivityLog save(ActivityLog log);
}
