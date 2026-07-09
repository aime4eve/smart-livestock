package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

/**
 * Calculates device health scores based on operational telemetry.
 * Five dimensions: battery, signal, online status, anti-disassembly, data reporting.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceHealthScoreService {

    private final DeviceRepository deviceRepository;
    private final DeviceTelemetryLogRepository deviceTelemetryLogRepository;

    /**
     * Calculate device health score (0-100).
     */
    @Transactional(readOnly = true)
    public DeviceHealthScore calculate(Long deviceId) {
        Device device = deviceRepository.findById(deviceId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.deviceNotFound", new Object[]{deviceId}));

        int batteryScore = scoreBattery(device.getBatteryLevel());
        int signalScore = scoreSignal(device.getRssi(), device.getSnr());
        int onlineScore = scoreOnline(device.getLastOnlineAt());
        int tamperScore = scoreTamper(device.getAntiDisassemblyStatus());
        int reportScore = scoreReporting(device);

        int total = (int) Math.round(
                batteryScore * 0.30 +
                signalScore * 0.25 +
                onlineScore * 0.25 +
                tamperScore * 0.10 +
                reportScore * 0.10
        );

        String grade = total >= 80 ? "HEALTHY" : total >= 60 ? "WARNING" : "CRITICAL";

        return new DeviceHealthScore(deviceId, total, grade,
                Map.of(
                    "battery", batteryScore,
                    "signal", signalScore,
                    "online", onlineScore,
                    "tamper", tamperScore,
                    "reporting", reportScore
                ));
    }

    private int scoreBattery(Integer battery) {
        if (battery == null) return 50;
        if (battery >= 80) return 100;
        if (battery >= 50) return 70;
        if (battery >= 20) return 40;
        return 10;
    }

    private int scoreSignal(Integer rssi, java.math.BigDecimal snr) {
        if (rssi == null) return 50;
        if (rssi >= -50) return 100;
        if (rssi >= -70) return 80;
        if (rssi >= -90) return 50;
        return 20;
    }

    private int scoreOnline(Instant lastOnlineAt) {
        if (lastOnlineAt == null) return 10;
        long hoursAgo = Duration.between(lastOnlineAt, Instant.now()).toHours();
        if (hoursAgo < 1) return 100;
        if (hoursAgo < 6) return 70;
        if (hoursAgo < 24) return 40;
        return 10;
    }

    private int scoreTamper(Integer antiDisassembly) {
        if (antiDisassembly == null || antiDisassembly == 0) return 100;
        return 0;
    }

    private int scoreReporting(Device device) {
        // Check if recent telemetry logs exist
        boolean hasRecent = deviceTelemetryLogRepository.findLatestByDeviceId(device.getId())
                .map(log -> Duration.between(log.getReportTime(), Instant.now()).toHours() < 2)
                .orElse(false);
        return hasRecent ? 100 : 20;
    }

    /** Device health score result DTO. */
    public record DeviceHealthScore(
            Long deviceId,
            int score,
            String grade,
            Map<String, Integer> dimensions
    ) {}
}
