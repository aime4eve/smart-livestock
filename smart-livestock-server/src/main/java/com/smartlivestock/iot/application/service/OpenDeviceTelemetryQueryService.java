package com.smartlivestock.iot.application.service;

import com.smartlivestock.iot.application.dto.OpenDeviceTelemetryDtos.DeviceFrameReading;
import com.smartlivestock.iot.application.dto.OpenDeviceTelemetryDtos.DeviceTelemetry;
import com.smartlivestock.iot.application.dto.OpenDeviceTelemetryDtos.SeriesPage;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.shared.ratelimit.RateLimitService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Device-dimension raw telemetry for the Open API (NIX-323).
 *
 * Also carries the telemetry-export daily budget check: a 24h sliding-window
 * counter in Redis keyed per tenant, so degraded (expired → basic) tenants
 * are limited but never rejected outright — matching the 2026-10-26 ruling.
 * Deliberately NOT QuotaCheckService, whose isActiveOrTrial gate would deny
 * expired tenants entirely.
 */
@Service
@RequiredArgsConstructor
public class OpenDeviceTelemetryQueryService {

    public static final String TELEMETRY_EXPORT_FEATURE = "telemetry_export";

    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    private final DeviceRepository deviceRepository;
    private final RateLimitService rateLimitService;

    @Transactional(readOnly = true)
    public DeviceTelemetry queryByDevice(Long deviceId, Instant from, Instant to, int page, int pageSize) {
        String deviceCode = deviceRepository.findById(deviceId)
                .map(Device::getDeviceCode)
                .orElse(null);
        var result = deviceTelemetryLogRepository.findPageByDevice(deviceId, from, to, page, pageSize);
        List<DeviceFrameReading> readings = result.items().stream().map(OpenDeviceTelemetryQueryService::toReading).toList();
        return new DeviceTelemetry(deviceId, deviceCode, from, to,
                new SeriesPage<>(readings, page, pageSize, result.total()));
    }

    /**
     * Consume one unit of the tenant's 24h telemetry-export budget.
     * Returns the result so the caller can surface remaining quota.
     */
    public RateLimitService.RateLimitResult consumeExportBudget(Long tenantId, Integer limitPerDay) {
        if (limitPerDay == null) {
            // Unlimited tier (enterprise): nothing to record.
            return new RateLimitService.RateLimitResult(true, Integer.MAX_VALUE, Integer.MAX_VALUE, 0L);
        }
        return rateLimitService.checkAndRecord(
                "quota:telemetry_export:" + tenantId, limitPerDay, Duration.ofHours(24));
    }

    private static DeviceFrameReading toReading(DeviceTelemetryLog log) {
        return new DeviceFrameReading(
                log.getReportTime(),
                log.getBatteryLevel(),
                log.getRssi(),
                log.getSnr(),
                log.getStepNumber(),
                log.getGastricMotility(),
                log.getAccelXG(),
                log.getAccelYG(),
                log.getAccelZG(),
                log.getAccelMagnitudeG(),
                log.getLatitude(),
                log.getLongitude(),
                log.getSource() != null ? log.getSource().name() : null);
    }
}
