package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.dto.DatagenClearResultDto;
import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;
import com.smartlivestock.datagen.domain.repository.DatagenDeviceAssignmentRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DatagenDataQueryService {
    private static final ZoneId STATS_ZONE = ZoneId.of("Asia/Shanghai");

    private final DatagenDeviceAssignmentRepository assignmentRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public List<Long> assignedDeviceIds(Long controlId) {
        return assignmentRepository.findByControlId(controlId).stream()
                .map(DatagenDeviceAssignment::getDeviceId)
                .distinct()
                .toList();
    }

    public Instant todayStart() {
        return Instant.now().atZone(STATS_ZONE).toLocalDate()
                .atStartOfDay(STATS_ZONE).toInstant();
    }

    public Instant lastGeneratedAt(List<Long> deviceIds) {
        if (deviceIds.isEmpty()) return null;
        Object value = entityManager.createNativeQuery("""
                SELECT MAX(report_time)
                FROM device_telemetry_logs
                WHERE device_id IN (:deviceIds) AND source = 'DATAGEN'
                """)
                .setParameter("deviceIds", deviceIds)
                .getSingleResult();
        return value instanceof Timestamp timestamp ? timestamp.toInstant() : null;
    }

    public Map<Long, Instant> lastGeneratedByDevice(List<Long> deviceIds) {
        if (deviceIds.isEmpty()) return Map.of();
        List<Object[]> rows = entityManager.createNativeQuery("""
                SELECT device_id, MAX(report_time)
                FROM device_telemetry_logs
                WHERE device_id IN (:deviceIds) AND source = 'DATAGEN'
                GROUP BY device_id
                """)
                .setParameter("deviceIds", deviceIds)
                .getResultList();
        Map<Long, Instant> result = new HashMap<>();
        for (Object[] row : rows) {
            if (row[1] instanceof Timestamp timestamp) {
                result.put(((Number) row[0]).longValue(), timestamp.toInstant());
            }
        }
        return result;
    }

    public DatagenStatsParts statsByDeviceIds(List<Long> deviceIds, Instant from, Instant to) {
        long telemetry = countDeviceRows(
                "device_telemetry_logs", "report_time", deviceIds, from, to);
        long gps = countDeviceRows("gps_logs", "recorded_at", deviceIds, from, to);
        long temperature = countDeviceRows(
                "temperature_logs", "recorded_at", deviceIds, from, to);
        long motility = countDeviceRows(
                "rumen_motility_logs", "recorded_at", deviceIds, from, to);
        long activity = countDeviceRows(
                "activity_logs", "recorded_at", deviceIds, from, to);
        return new DatagenStatsParts(
                telemetry, gps, temperature, motility, activity);
    }

    public DatagenClearResultDto preview(Long farmId, Instant from, Instant to) {
        return queryOrClear(farmId, from, to, false);
    }

    public DatagenClearResultDto clear(Long farmId, Instant from, Instant to) {
        return queryOrClear(farmId, from, to, true);
    }

    private DatagenClearResultDto queryOrClear(
            Long farmId, Instant from, Instant to, boolean delete) {
        List<Long> farmDeviceIds = entityManager.createNativeQuery("""
                SELECT DISTINCT a.device_id
                FROM datagen_device_assignments a
                JOIN datagen_farm_controls c ON c.id = a.control_id
                WHERE c.farm_id = :farmId
                """, Long.class)
                .setParameter("farmId", farmId)
                .getResultStream()
                .map(value -> ((Number) value).longValue())
                .toList();

        if (farmDeviceIds.isEmpty()) {
            return new DatagenClearResultDto(0, 0, 0, 0, 0, 0, 0, 0,
                    countUnattributableHealth(farmId, from, to),
                    countUnattributableAlerts(farmId, from, to),
                    "datagenConsoleCrossFarmLimit");
        }

        long telemetry = deviceAction(
                "device_telemetry_logs", "report_time", farmDeviceIds, from, to, delete);
        long gps = deviceAction(
                "gps_logs", "recorded_at", farmDeviceIds, from, to, delete);
        long temperature = deviceAction(
                "temperature_logs", "recorded_at", farmDeviceIds, from, to, delete);
        long motility = deviceAction(
                "rumen_motility_logs", "recorded_at", farmDeviceIds, from, to, delete);
        long activity = deviceAction(
                "activity_logs", "recorded_at", farmDeviceIds, from, to, delete);
        long estrus = farmAction(
                "estrus_scores", "scored_at", farmId, from, to, delete);
        long anomaly = farmAction(
                "anomaly_scores", "created_at", farmId, from, to, delete);
        long alerts = farmAction("alerts", "created_at", farmId, from, to, delete);

        return new DatagenClearResultDto(
                telemetry, gps, temperature, motility, activity,
                estrus, anomaly, alerts,
                countUnattributableHealth(farmId, from, to),
                countUnattributableAlerts(farmId, from, to),
                "datagenConsoleCrossFarmLimit");
    }

    private long countDeviceRows(
            String table, String timeColumn, List<Long> deviceIds, Instant from, Instant to) {
        return executeDevice(table, timeColumn, deviceIds, from, to, false);
    }

    private long deviceAction(
            String table, String timeColumn, List<Long> deviceIds,
            Instant from, Instant to, boolean delete) {
        return executeDevice(table, timeColumn, deviceIds, from, to, delete);
    }

    private long farmAction(
            String table, String timeColumn, Long farmId,
            Instant from, Instant to, boolean delete) {
        return executeFarm(table, timeColumn, farmId, from, to, delete);
    }

    private long executeDevice(
            String table, String timeColumn, List<Long> deviceIds,
            Instant from, Instant to, boolean delete) {
        String verb = delete ? "DELETE FROM" : "SELECT COUNT(*) FROM";
        String sql = verb + " " + table + " WHERE device_id IN (:deviceIds) "
                + "AND source = 'DATAGEN' AND " + timeColumn + " >= :from AND "
                + timeColumn + " < :to";
        Object result = entityManager.createNativeQuery(sql)
                .setParameter("deviceIds", deviceIds)
                .setParameter("from", Timestamp.from(from))
                .setParameter("to", Timestamp.from(to))
                .getSingleResult();
        return ((Number) result).longValue();
    }

    private long executeFarm(
            String table, String timeColumn, Long farmId,
            Instant from, Instant to, boolean delete) {
        String verb = delete ? "DELETE FROM" : "SELECT COUNT(*) FROM";
        String sql = verb + " " + table + " WHERE farm_id = :farmId "
                + "AND source = 'DATAGEN' AND " + timeColumn + " >= :from AND "
                + timeColumn + " < :to";
        Object result = entityManager.createNativeQuery(sql)
                .setParameter("farmId", farmId)
                .setParameter("from", Timestamp.from(from))
                .setParameter("to", Timestamp.from(to))
                .getSingleResult();
        return ((Number) result).longValue();
    }

    private long countUnattributableHealth(Long farmId, Instant from, Instant to) {
        long deviceCount = asLong(entityManager.createNativeQuery("""
                SELECT COUNT(*)
                FROM temperature_logs t
                JOIN datagen_device_assignments a ON a.device_id = t.device_id
                JOIN datagen_farm_controls c ON c.id = a.control_id
                WHERE c.farm_id = :farmId AND t.source = 'UNKNOWN'
                  AND t.recorded_at >= :from AND t.recorded_at < :to
                """, Long.class)
                .setParameter("farmId", farmId)
                .setParameter("from", Timestamp.from(from))
                .setParameter("to", Timestamp.from(to))
                .getSingleResult());
        long livestockCount = asLong(entityManager.createNativeQuery("""
                SELECT COUNT(*)
                FROM rumen_motility_logs m
                JOIN datagen_device_assignments a ON a.device_id = m.device_id
                JOIN datagen_farm_controls c ON c.id = a.control_id
                WHERE c.farm_id = :farmId AND m.source = 'UNKNOWN'
                  AND m.recorded_at >= :from AND m.recorded_at < :to
                """, Long.class)
                .setParameter("farmId", farmId)
                .setParameter("from", Timestamp.from(from))
                .setParameter("to", Timestamp.from(to))
                .getSingleResult());
        long activityCount = asLong(entityManager.createNativeQuery("""
                SELECT COUNT(*)
                FROM activity_logs x
                JOIN datagen_device_assignments a ON a.device_id = x.device_id
                JOIN datagen_farm_controls c ON c.id = a.control_id
                WHERE c.farm_id = :farmId AND x.source = 'UNKNOWN'
                  AND x.recorded_at >= :from AND x.recorded_at < :to
                """, Long.class)
                .setParameter("farmId", farmId)
                .setParameter("from", Timestamp.from(from))
                .setParameter("to", Timestamp.from(to))
                .getSingleResult());
        return deviceCount + livestockCount + activityCount;
    }

    private long countUnattributableAlerts(Long farmId, Instant from, Instant to) {
        Object result = entityManager.createNativeQuery("""
                SELECT COUNT(*)
                FROM alerts
                WHERE farm_id = :farmId AND source = 'RULE'
                  AND created_at >= :from AND created_at < :to
                """)
                .setParameter("farmId", farmId)
                .setParameter("from", Timestamp.from(from))
                .setParameter("to", Timestamp.from(to))
                .getSingleResult();
        return ((Number) result).longValue();
    }

    private long asLong(Object value) {
        return value instanceof Number number ? number.longValue() : 0;
    }

    public record DatagenStatsParts(
            long telemetryRows, long gpsRows, long temperatureRows,
            long motilityRows, long activityRows) {}
}
