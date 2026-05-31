package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.RumenMotilityLog;

import java.time.Instant;
import java.util.List;

public interface RumenMotilityLogRepository {
    List<RumenMotilityLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    List<RumenMotilityLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    RumenMotilityLog save(RumenMotilityLog log);
}
