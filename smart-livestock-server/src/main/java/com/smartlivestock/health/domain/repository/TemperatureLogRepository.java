package com.smartlivestock.health.domain.repository;

import com.smartlivestock.shared.domain.TelemetryPage;
import com.smartlivestock.health.domain.model.DailyTemperatureStat;
import com.smartlivestock.health.domain.model.TemperatureLog;

import java.time.Instant;
import java.util.List;

public interface TemperatureLogRepository {
    List<TemperatureLog> findByLivestockIdAndTimeRange(Long livestockId, Instant from, Instant to);
    TelemetryPage<TemperatureLog> findPageByLivestock(Long livestockId, Instant from, Instant to, int page, int pageSize);
    /** Paged batch read across livestock for full-farm export (NIX-325). */
    TelemetryPage<TemperatureLog> findPageByLivestockIn(java.util.List<Long> livestockIds, org.springframework.data.domain.Pageable pageable);
    TelemetryPage<TemperatureLog> findPageByDevice(Long deviceId, Instant from, Instant to, int page, int pageSize);
    List<TemperatureLog> findLatestByLivestockIds(List<Long> livestockIds, int limitPerLivestock);
    List<TemperatureLog> findByLivestockIdOrderByRecordedAtDesc(Long livestockId, int limit);
    List<TemperatureLog> findByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to);
    boolean existsByDeviceIdAndRecordedAtAndSource(
            Long deviceId, Instant recordedAt, String source);
    TemperatureLog save(TemperatureLog log);

    /**
     * Daily AVG temperature + normal-reading ratio inputs for the
     * /health/stats trends (NIX-323: real aggregation, no placeholders).
     */
    java.util.List<DailyTemperatureStat> aggregateDailyStats(java.util.List<Long> livestockIds, java.time.Instant since);
}
