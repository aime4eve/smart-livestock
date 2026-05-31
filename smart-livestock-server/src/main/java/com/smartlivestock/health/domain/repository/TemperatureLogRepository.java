package com.smartlivestock.health.domain.repository;

import com.smartlivestock.health.domain.model.TemperatureLog;

import java.time.Instant;
import java.util.List;

public interface TemperatureLogRepository {
    List<TemperatureLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    List<TemperatureLog> findLatestByLivestockIds(List<Long> livestockIds, int limitPerLivestock);
    List<TemperatureLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    TemperatureLog save(TemperatureLog log);
}
