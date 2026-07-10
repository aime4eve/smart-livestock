package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.ActivityLog;

import java.time.Instant;
import java.util.List;

public interface ActivityLogRepository {
    List<ActivityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    List<ActivityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    ActivityLog save(ActivityLog log);
}
