package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.GpsLog;
import com.smartlivestock.iot.domain.port.dto.GpsPointWithTelemetry;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.infrastructure.persistence.entity.GpsLogJpaEntity;
import com.smartlivestock.iot.infrastructure.persistence.mapper.GpsLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Repository
@RequiredArgsConstructor
public class JpaGpsLogRepositoryImpl implements GpsLogRepository {

    private final SpringDataGpsLogRepository springDataRepo;

    @Override
    public GpsLog save(GpsLog gpsLog) {
        // Idempotent upsert on (device_id, recorded_at): re-syncs from the
        // agentic-platform no longer stack duplicate rows. Then re-read the
        // canonical row so callers keep getting back the persisted entity.
        springDataRepo.upsertByDeviceAndRecordedAt(
                gpsLog.getDeviceId(),
                gpsLog.getLatitude(),
                gpsLog.getLongitude(),
                gpsLog.getAccuracy(),
                gpsLog.getRecordedAt());
        springDataRepo.flush();
        List<GpsLogJpaEntity> rows = springDataRepo.findByDeviceIdAndRecordedAtBetween(
                gpsLog.getDeviceId(), gpsLog.getRecordedAt(), gpsLog.getRecordedAt());
        return rows.isEmpty() ? gpsLog : GpsLogMapper.toDomain(rows.get(0));
    }

    @Override
    public List<GpsLog> findByDeviceId(Long deviceId) {
        return springDataRepo.findByDeviceId(deviceId).stream()
                .map(GpsLogMapper::toDomain)
                .toList();
    }

    @Override
    public List<GpsLog> findByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to) {
        return springDataRepo.findByDeviceIdAndRecordedAtBetween(deviceId, from, to).stream()
                .map(GpsLogMapper::toDomain)
                .toList();
    }

    @Override
    public long countByDeviceIdAndRecordedAtBetween(Long deviceId, Instant from, Instant to) {
        return springDataRepo.countByDeviceIdAndRecordedAtBetween(deviceId, from, to);
    }

    @Override
    public List<GpsLog> sampleByDeviceIdAndTimeRange(Long deviceId, Instant from, Instant to, long stride) {
        List<Long> ids = springDataRepo.sampleIdsByDeviceIdAndTimeRange(deviceId, from, to, stride);
        if (ids.isEmpty()) {
            return List.of();
        }
        return springDataRepo.findAllByIdInOrderByRecordedAt(ids).stream()
                .map(GpsLogMapper::toDomain)
                .toList();
    }

    @Override
    public List<GpsPointWithTelemetry> findByDeviceIdAndTimeRangeWithTelemetry(Long deviceId, Instant from, Instant to) {
        List<Object[]> rows = springDataRepo.findGpsWithTelemetryByDeviceIdAndTimeRange(deviceId, from, to);
        List<GpsPointWithTelemetry> result = new ArrayList<>(rows.size());
        for (Object[] row : rows) {
            result.add(new GpsPointWithTelemetry(
                    toBigDecimal(row[0]),
                    toBigDecimal(row[1]),
                    toBigDecimal(row[2]),
                    toInstant(row[3]),
                    row[4] != null ? ((Number) row[4]).intValue() : null,
                    toBigDecimal(row[5]),
                    row[6] != null ? row[6].toString() : null
            ));
        }
        return result;
    }

    private static BigDecimal toBigDecimal(Object o) {
        if (o == null) return null;
        if (o instanceof BigDecimal bd) return bd;
        if (o instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        return new BigDecimal(o.toString());
    }

    private static Instant toInstant(Object o) {
        if (o == null) return null;
        if (o instanceof Instant inst) return inst;
        if (o instanceof java.sql.Timestamp ts) return ts.toInstant();
        if (o instanceof Date d) return d.toInstant();
        if (o instanceof java.time.OffsetDateTime odt) return odt.toInstant();
        throw new IllegalStateException("Cannot convert to Instant: " + o.getClass());
    }
}
