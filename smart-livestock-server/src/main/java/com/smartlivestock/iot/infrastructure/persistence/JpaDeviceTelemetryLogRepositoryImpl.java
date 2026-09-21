package com.smartlivestock.iot.infrastructure.persistence;

import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.infrastructure.persistence.mapper.DeviceTelemetryLogMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaDeviceTelemetryLogRepositoryImpl implements DeviceTelemetryLogRepository {

    private final SpringDataDeviceTelemetryLogRepository springDataRepo;

    @Override
    public DeviceTelemetryLog save(DeviceTelemetryLog log) {
        return DeviceTelemetryLogMapper.toDomain(springDataRepo.save(DeviceTelemetryLogMapper.toJpaEntity(log)));
    }

    @Override
    public Optional<DeviceTelemetryLog> findLatestByDeviceId(Long deviceId) {
        return springDataRepo.findLatestByDeviceId(deviceId, PageRequest.of(0, 1))
                .stream().findFirst()
                .map(DeviceTelemetryLogMapper::toDomain);
    }

    @Override
    public Optional<DeviceTelemetryLog> findLatestStepNumberByDeviceIdAndReportTimeBefore(
            Long deviceId, Instant reportTime) {
        return springDataRepo.findLatestStepNumberByDeviceIdAndReportTimeBefore(
                        deviceId, reportTime, PageRequest.of(0, 1))
                .stream().findFirst()
                .map(DeviceTelemetryLogMapper::toDomain);
    }

    @Override
    public Optional<DeviceTelemetryLog> findLatestGastricMotilityByDeviceIdAndReportTimeBefore(
            Long deviceId, Instant reportTime) {
        return springDataRepo.findLatestGastricMotilityByDeviceIdAndReportTimeBefore(
                        deviceId, reportTime, PageRequest.of(0, 1))
                .stream().findFirst()
                .map(DeviceTelemetryLogMapper::toDomain);
    }

    @Override
    public Optional<DeviceTelemetryLog> findLatestGpsByDeviceIdAndReportTimeBefore(
            Long deviceId, Instant reportTime) {
        return springDataRepo.findLatestGpsByDeviceIdAndReportTimeBefore(
                        deviceId, reportTime, PageRequest.of(0, 1))
                .stream().findFirst()
                .map(DeviceTelemetryLogMapper::toDomain);
    }

    @Override
    public boolean existsByDeviceIdAndReportTime(Long deviceId, Instant reportTime) {
        return springDataRepo.existsByDeviceIdAndReportTime(deviceId, reportTime);
    }

    @Override
    public List<Instant> findReportTimesByDeviceIdAndReportTimeBetween(Long deviceId, Instant min, Instant max) {
        return springDataRepo.findReportTimesByDeviceIdAndReportTimeBetween(deviceId, min, max);
    }

    @Override
    public List<com.smartlivestock.iot.domain.model.GatewayUsageSummary> aggregateGatewayUsage(
            List<Long> deviceIds, Instant since, Instant statsSince) {
        if (deviceIds == null || deviceIds.isEmpty()) return List.of();
        // Native query: MAX(report_time) comes back as java.sql.Timestamp.
        return springDataRepo.aggregateGatewayUsageRows(deviceIds, since, statsSince).stream()
                .map(row -> new com.smartlivestock.iot.domain.model.GatewayUsageSummary(
                        (String) row[0],
                        row[1] == null ? null : ((java.sql.Timestamp) row[1]).toInstant(),
                        ((Number) row[2]).longValue(),
                        row[3] == null ? null : ((Number) row[3]).doubleValue()))
                .toList();
    }

    @Override
    public List<String> findDistinctGatewayIds(Instant since) {
        return springDataRepo.findDistinctGatewayIds(since);
    }

    @Override
    public List<com.smartlivestock.iot.domain.model.GatewayDistanceStats> aggregateGatewayDistances(
            Long deviceId, Instant since) {
        // Native query yields 5 columns: gateway_id, last_time, frames, p50, p95.
        // latestMeters is filled by GatewayDistanceService from the latest fix.
        return springDataRepo.aggregateGatewayDistanceRows(deviceId, since).stream()
                .map(row -> new com.smartlivestock.iot.domain.model.GatewayDistanceStats(
                        (String) row[0],
                        row[1] == null ? null : ((java.sql.Timestamp) row[1]).toInstant(),
                        ((Number) row[2]).longValue(),
                        Double.NaN,
                        row[3] == null ? Double.NaN : ((Number) row[3]).doubleValue(),
                        row[4] == null ? Double.NaN : ((Number) row[4]).doubleValue()))
                .toList();
    }

    @Override
    public List<com.smartlivestock.iot.domain.model.GatewayLatestFix> findLatestFixesByGateway(
            Long deviceId, Instant since) {
        return springDataRepo.findLatestFixRowsByGateway(deviceId, since).stream()
                .map(row -> new com.smartlivestock.iot.domain.model.GatewayLatestFix(
                        (String) row[0],
                        row[1] == null ? null : ((java.sql.Timestamp) row[1]).toInstant(),
                        toBigDecimal(row[2]),
                        toBigDecimal(row[3])))
                .toList();
    }

    private static java.math.BigDecimal toBigDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof java.math.BigDecimal bd) return bd;
        return new java.math.BigDecimal(value.toString());
    }

    @Override
    public Optional<com.smartlivestock.iot.domain.model.LinkQualityStats> recentLinkQuality(
            Long deviceId, String gatewayId, Instant since, int limitFrames) {
        return springDataRepo.recentLinkQualityRow(deviceId, gatewayId, since, limitFrames).stream()
                .findFirst()
                .filter(row -> row[0] != null)
                .map(row -> new com.smartlivestock.iot.domain.model.LinkQualityStats(
                        ((Number) row[0]).doubleValue(),
                        row[1] == null ? null : ((Number) row[1]).doubleValue(),
                        ((Number) row[2]).intValue()));
    }

    @Override
    public List<com.smartlivestock.iot.domain.model.RssiDistanceSample> rssiDistanceSamples(
            String gatewayId, Instant since) {
        return springDataRepo.rssiDistanceSampleRows(gatewayId, since).stream()
                .map(row -> new com.smartlivestock.iot.domain.model.RssiDistanceSample(
                        ((Number) row[0]).intValue(),
                        ((Number) row[1]).doubleValue(),
                        row[2] == null ? null : ((java.sql.Timestamp) row[2]).toInstant()))
                .toList();
    }

    @Override
    public List<com.smartlivestock.iot.domain.model.GatewayLatestRssi> findLatestRssiByGateway(
            Long deviceId, Instant since) {
        return springDataRepo.latestRssiRowsByGateway(deviceId, since).stream()
                .map(row -> new com.smartlivestock.iot.domain.model.GatewayLatestRssi(
                        (String) row[0],
                        row[1] == null ? null : ((java.sql.Timestamp) row[1]).toInstant(),
                        ((Number) row[2]).intValue()))
                .toList();
    }

    @Override
    public List<Double> roamDistanceSamples(Long deviceId, Instant from, Instant to) {
        return springDataRepo.roamDistanceSampleRows(deviceId, from, to);
    }

    @Override
    public List<com.smartlivestock.iot.domain.model.CoverageCellRow> coverageCellRows(
            List<Long> deviceIds, Instant since, int minCellFrames) {
        if (deviceIds == null || deviceIds.isEmpty()) return List.of();
        return springDataRepo.coverageCellRows(deviceIds, since, minCellFrames).stream()
                .map(row -> new com.smartlivestock.iot.domain.model.CoverageCellRow(
                        ((Number) row[0]).intValue(),
                        ((Number) row[1]).intValue(),
                        ((Number) row[2]).longValue(),
                        row[3] == null ? Double.NaN : ((Number) row[3]).doubleValue(),
                        row[4] == null ? Double.NaN : ((Number) row[4]).doubleValue(),
                        row[5] == null ? Double.NaN : ((Number) row[5]).doubleValue()))
                .toList();
    }

    @Override
    public com.smartlivestock.iot.domain.model.CoverageTierTotals coverageTierTotals(
            List<Long> deviceIds, Instant since) {
        if (deviceIds == null || deviceIds.isEmpty()) {
            return new com.smartlivestock.iot.domain.model.CoverageTierTotals(0, 0, 0, 0, null, null, null);
        }
        List<Object[]> rows = springDataRepo.coverageTierTotals(deviceIds, since);
        Object[] row = rows.isEmpty() ? null : rows.get(0);
        if (row == null || row[0] == null) {
            return new com.smartlivestock.iot.domain.model.CoverageTierTotals(0, 0, 0, 0, null, null, null);
        }
        return new com.smartlivestock.iot.domain.model.CoverageTierTotals(
                ((Number) row[0]).longValue(),
                ((Number) row[1]).longValue(),
                ((Number) row[2]).longValue(),
                ((Number) row[3]).longValue(),
                row[4] == null ? null : ((Number) row[4]).doubleValue(),
                row[5] == null ? null : ((Number) row[5]).doubleValue(),
                row[6] == null ? null : ((java.sql.Timestamp) row[6]).toInstant());
    }

    @Override
    public com.smartlivestock.iot.domain.model.WeakCentroidRow weakCentroid(
            List<Long> deviceIds, Instant since) {
        if (deviceIds == null || deviceIds.isEmpty()) {
            return new com.smartlivestock.iot.domain.model.WeakCentroidRow(null, null, 0);
        }
        List<Object[]> rows = springDataRepo.weakCentroidRow(deviceIds, since);
        Object[] row = rows.isEmpty() ? null : rows.get(0);
        if (row == null || row[0] == null) {
            return new com.smartlivestock.iot.domain.model.WeakCentroidRow(null, null, 0);
        }
        return new com.smartlivestock.iot.domain.model.WeakCentroidRow(
                ((Number) row[0]).doubleValue(),
                ((Number) row[1]).doubleValue(),
                ((Number) row[2]).longValue());
    }
}
