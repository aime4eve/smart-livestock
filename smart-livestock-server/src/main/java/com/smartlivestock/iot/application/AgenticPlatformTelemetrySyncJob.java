package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformHistoryDataClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;

/**
 * Syncs a single device's telemetry from agentic-middle-platform.
 * Called by AgenticPlatformSyncWorker (RocketMQ consumer).
 * <p>
 * Flow: read cursor → paginate report-record/page → parse decodeData → apply accel conversion → ingest().
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AgenticPlatformTelemetrySyncJob {

    private final DeviceRepository deviceRepository;
    private final AgenticPlatformHistoryDataClient historyClient;
    private final TelemetryIngestionService telemetryIngestionService;

    @Value("${agentic-platform.sync.page-size:100}")
    private int pageSize;

    /**
     * Sync a single device by its local deviceId.
     */
    public void syncDevice(Long deviceId) {
        Device device = deviceRepository.findById(deviceId).orElse(null);
        if (device == null || device.getPlatformDeviceId() == null) return;

        Instant cursor = device.getLastTelemetrySyncedAt();
        int page = 1;
        int processed = 0;

        while (true) {
            InternalResponse<ReportRecordPageResp> resp;
            try {
                resp = historyClient.queryReportRecords(
                        String.valueOf(device.getPlatformDeviceId()), page, pageSize);
            } catch (Exception e) {
                log.error("[PlatformSync] device {} report-record fetch failed: {}", deviceId, e.getMessage());
                throw e;
            }

            if (resp == null || !resp.isOk() || resp.getData() == null
                    || resp.getData().getRecords() == null || resp.getData().getRecords().isEmpty()) {
                break;
            }

            for (ReportRecordPageResp.ReportRecord record : resp.getData().getRecords()) {
                Instant reportTime = AgenticPlatformReportData.parseReportTime(record.getReportTime());

                // Skip already-synced records (cursor dedup)
                if (cursor != null && !reportTime.isAfter(cursor)) continue;

                // Parse decodeData + top-level fields → standard readings Map
                Map<String, Object> readings = AgenticPlatformReportData.toReadings(record);

                // Apply LIS3DH accelerometer conversion (方案 B: data-entry boundary)
                AgenticPlatformReportData.applyAccelerometerConversion(readings);

                // Ingest via unified entry point
                telemetryIngestionService.ingest(deviceId, readings, reportTime, TelemetrySource.AGENTIC_PLATFORM);
                processed++;
            }

            if (resp.getData().getRecords().size() < pageSize) break;
            page++;
        }

        if (processed > 0) {
            log.debug("[PlatformSync] device {} synced {} records", deviceId, processed);
        }
    }
}
