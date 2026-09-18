package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceTelemetryLogJpaEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface SpringDataDeviceTelemetryLogRepository extends JpaRepository<DeviceTelemetryLogJpaEntity, Long> {

    @Query("SELECT t FROM DeviceTelemetryLogJpaEntity t WHERE t.deviceId = :deviceId ORDER BY t.reportTime DESC")
    List<DeviceTelemetryLogJpaEntity> findLatestByDeviceId(@Param("deviceId") Long deviceId, Pageable pageable);

    @Query("""
            SELECT t FROM DeviceTelemetryLogJpaEntity t
            WHERE t.deviceId = :deviceId
              AND t.reportTime < :reportTime
              AND t.stepNumber IS NOT NULL
            ORDER BY t.reportTime DESC
            """)
    List<DeviceTelemetryLogJpaEntity> findLatestStepNumberByDeviceIdAndReportTimeBefore(
            @Param("deviceId") Long deviceId,
            @Param("reportTime") Instant reportTime,
            Pageable pageable);

    @Query("""
            SELECT t FROM DeviceTelemetryLogJpaEntity t
            WHERE t.deviceId = :deviceId
              AND t.reportTime < :reportTime
              AND t.gastricMotility IS NOT NULL
            ORDER BY t.reportTime DESC
            """)
    List<DeviceTelemetryLogJpaEntity> findLatestGastricMotilityByDeviceIdAndReportTimeBefore(
            @Param("deviceId") Long deviceId,
            @Param("reportTime") Instant reportTime,
            Pageable pageable);

    @Query("""
            SELECT t FROM DeviceTelemetryLogJpaEntity t
            WHERE t.deviceId = :deviceId
              AND t.reportTime < :reportTime
              AND t.latitude IS NOT NULL
              AND t.longitude IS NOT NULL
              AND t.latitude <> 0
              AND t.longitude <> 0
            ORDER BY t.reportTime DESC
            """)
    List<DeviceTelemetryLogJpaEntity> findLatestGpsByDeviceIdAndReportTimeBefore(
            @Param("deviceId") Long deviceId,
            @Param("reportTime") Instant reportTime,
            Pageable pageable);

    boolean existsByDeviceIdAndReportTime(Long deviceId, Instant reportTime);

    @Query("SELECT t.reportTime FROM DeviceTelemetryLogJpaEntity t WHERE t.deviceId = :deviceId AND t.reportTime BETWEEN :startTime AND :endTime")
    List<Instant> findReportTimesByDeviceIdAndReportTimeBetween(@Param("deviceId") Long deviceId,
                                                                @Param("startTime") Instant startTime,
                                                                @Param("endTime") Instant endTime);

    // --- Gateway distance features (NIX-219) ---

    @Query("""
            SELECT t.gatewayId, MAX(t.reportTime), COUNT(t), AVG(t.rssi)
            FROM DeviceTelemetryLogJpaEntity t
            WHERE t.deviceId IN :deviceIds
              AND t.reportTime >= :since
              AND t.gatewayId IS NOT NULL AND t.gatewayId <> ''
            GROUP BY t.gatewayId
            """)
    List<Object[]> aggregateGatewayUsageRows(@Param("deviceIds") List<Long> deviceIds,
                                             @Param("since") Instant since);

    @Query("""
            SELECT DISTINCT t.gatewayId FROM DeviceTelemetryLogJpaEntity t
            WHERE t.reportTime >= :since
              AND t.gatewayId IS NOT NULL AND t.gatewayId <> ''
            """)
    List<String> findDistinctGatewayIds(@Param("since") Instant since);

    /**
     * Per-gateway distance statistics from frame-level Haversine distances.
     * Percentiles need the distance as a per-row expression, hence the subquery;
     * only valid coordinates and registered gateways participate (governance
     * pre-filter, NIX-220). Native SQL for PERCENTILE_CONT.
     */
    @Query(value = """
            SELECT sub.gateway_id,
                   MAX(sub.report_time)                                        AS last_time,
                   COUNT(*)                                                    AS frames,
                   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sub.dist)       AS p50,
                   PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sub.dist)      AS p95
            FROM (
                SELECT t.gateway_id,
                       t.report_time,
                       6371000 * 2 * asin(sqrt(
                           power(sin(radians(t.latitude - g.latitude) / 2), 2)
                           + cos(radians(g.latitude)) * cos(radians(t.latitude))
                               * power(sin(radians(t.longitude - g.longitude) / 2), 2)
                       )) AS dist
                FROM device_telemetry_logs t
                JOIN gateway_registry g ON g.gateway_id = t.gateway_id
                WHERE t.device_id = :deviceId
                  AND t.report_time >= :since
                  AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
                  AND t.latitude BETWEEN -90 AND 90
                  AND t.longitude BETWEEN -180 AND 180
                  AND NOT (t.latitude = 0 AND t.longitude = 0)
            ) sub
            GROUP BY sub.gateway_id
            """, nativeQuery = true)
    List<Object[]> aggregateGatewayDistanceRows(@Param("deviceId") Long deviceId,
                                                @Param("since") Instant since);

    @Query(value = """
            SELECT DISTINCT ON (t.gateway_id)
                   t.gateway_id, t.report_time, t.latitude, t.longitude
            FROM device_telemetry_logs t
            WHERE t.device_id = :deviceId
              AND t.report_time >= :since
              AND t.gateway_id IS NOT NULL AND t.gateway_id <> ''
              AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
              AND t.latitude BETWEEN -90 AND 90
              AND t.longitude BETWEEN -180 AND 180
              AND NOT (t.latitude = 0 AND t.longitude = 0)
            ORDER BY t.gateway_id, t.report_time DESC
            """, nativeQuery = true)
    List<Object[]> findLatestFixRowsByGateway(@Param("deviceId") Long deviceId,
                                              @Param("since") Instant since);

    @Query(value = """
            SELECT AVG(t.rssi), AVG(t.snr), COUNT(*)
            FROM (
                SELECT rssi, snr
                FROM device_telemetry_logs
                WHERE device_id = :deviceId
                  AND gateway_id = :gatewayId
                  AND report_time >= :since
                  AND rssi IS NOT NULL
                ORDER BY report_time DESC
                LIMIT :limitFrames
            ) t
            """, nativeQuery = true)
    List<Object[]> recentLinkQualityRow(@Param("deviceId") Long deviceId,
                                        @Param("gatewayId") String gatewayId,
                                        @Param("since") Instant since,
                                        @Param("limitFrames") int limitFrames);

    @Query(value = """
            SELECT t.rssi,
                   6371000 * 2 * asin(sqrt(
                       power(sin(radians(t.latitude - g.latitude) / 2), 2)
                       + cos(radians(g.latitude)) * cos(radians(t.latitude))
                           * power(sin(radians(t.longitude - g.longitude) / 2), 2)
                   )),
                   t.report_time
            FROM device_telemetry_logs t
            JOIN gateway_registry g ON g.gateway_id = t.gateway_id
            WHERE t.gateway_id = :gatewayId
              AND t.report_time >= :since
              AND t.rssi IS NOT NULL
              AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
              AND t.latitude BETWEEN -90 AND 90
              AND t.longitude BETWEEN -180 AND 180
              AND NOT (t.latitude = 0 AND t.longitude = 0)
            """, nativeQuery = true)
    List<Object[]> rssiDistanceSampleRows(@Param("gatewayId") String gatewayId,
                                          @Param("since") Instant since);

    @Query(value = """
            SELECT DISTINCT ON (t.gateway_id)
                   t.gateway_id, t.report_time, t.rssi
            FROM device_telemetry_logs t
            WHERE t.device_id = :deviceId
              AND t.report_time >= :since
              AND t.gateway_id IS NOT NULL AND t.gateway_id <> ''
              AND t.rssi IS NOT NULL
            ORDER BY t.gateway_id, t.report_time DESC
            """, nativeQuery = true)
    List<Object[]> latestRssiRowsByGateway(@Param("deviceId") Long deviceId,
                                           @Param("since") Instant since);

    @Query(value = """
            SELECT 6371000 * 2 * asin(sqrt(
                       power(sin(radians(t.latitude - g.latitude) / 2), 2)
                       + cos(radians(g.latitude)) * cos(radians(t.latitude))
                           * power(sin(radians(t.longitude - g.longitude) / 2), 2)
                   ))
            FROM device_telemetry_logs t
            JOIN gateway_registry g ON g.gateway_id = t.gateway_id
            WHERE t.device_id = :deviceId
              AND t.report_time >= :fromTime
              AND t.report_time < :toTime
              AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
              AND t.latitude BETWEEN -90 AND 90
              AND t.longitude BETWEEN -180 AND 180
              AND NOT (t.latitude = 0 AND t.longitude = 0)
            """, nativeQuery = true)
    List<Double> roamDistanceSampleRows(@Param("deviceId") Long deviceId,
                                        @Param("fromTime") Instant fromTime,
                                        @Param("toTime") Instant toTime);

    // --- F8 coverage diagnostics ---

    @Query(value = """
            SELECT ROUND(t.latitude / 0.0009)      AS gy,
                   ROUND(t.longitude / 0.0012)     AS gx,
                   COUNT(*)                        AS frames,
                   AVG(t.rssi)                     AS avg_rssi,
                   AVG(t.latitude)                 AS c_lat,
                   AVG(t.longitude)                AS c_lng
            FROM device_telemetry_logs t
            WHERE t.device_id IN (:deviceIds)
              AND t.report_time >= :since
              AND t.gateway_id IS NOT NULL AND t.gateway_id <> ''
              AND t.rssi IS NOT NULL
              AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
              AND t.latitude BETWEEN -90 AND 90
              AND t.longitude BETWEEN -180 AND 180
              AND NOT (t.latitude = 0 AND t.longitude = 0)
            GROUP BY gy, gx
            HAVING COUNT(*) >= :minCellFrames
            """, nativeQuery = true)
    List<Object[]> coverageCellRows(@Param("deviceIds") List<Long> deviceIds,
                                    @Param("since") Instant since,
                                    @Param("minCellFrames") int minCellFrames);

    @Query(value = """
            SELECT COUNT(*),
                   COUNT(*) FILTER (WHERE t.rssi >= -90),
                   COUNT(*) FILTER (WHERE t.rssi < -90 AND t.rssi >= -100),
                   COUNT(*) FILTER (WHERE t.rssi < -100),
                   AVG(t.latitude),
                   AVG(t.longitude),
                   MIN(t.report_time)
            FROM device_telemetry_logs t
            WHERE t.device_id IN (:deviceIds)
              AND t.report_time >= :since
              AND t.gateway_id IS NOT NULL AND t.gateway_id <> ''
              AND t.rssi IS NOT NULL
              AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
              AND t.latitude BETWEEN -90 AND 90
              AND t.longitude BETWEEN -180 AND 180
              AND NOT (t.latitude = 0 AND t.longitude = 0)
            """, nativeQuery = true)
    List<Object[]> coverageTierTotals(@Param("deviceIds") List<Long> deviceIds,
                                      @Param("since") Instant since);

    @Query(value = """
            SELECT AVG(t.latitude), AVG(t.longitude), COUNT(*)
            FROM device_telemetry_logs t
            WHERE t.device_id IN (:deviceIds)
              AND t.report_time >= :since
              AND t.gateway_id IS NOT NULL AND t.gateway_id <> ''
              AND t.rssi < -95
              AND t.latitude IS NOT NULL AND t.longitude IS NOT NULL
              AND t.latitude BETWEEN -90 AND 90
              AND t.longitude BETWEEN -180 AND 180
              AND NOT (t.latitude = 0 AND t.longitude = 0)
            """, nativeQuery = true)
    List<Object[]> weakCentroidRow(@Param("deviceIds") List<Long> deviceIds,
                                   @Param("since") Instant since);
}
