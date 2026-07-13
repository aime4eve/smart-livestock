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
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
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
     * <p>
     * Records are collected from all pages, filtered by cursor, then sorted ascending
     * by reportTime before processing. This ensures the newest record's gateway/rssi/snr
     * values win when ingested (each ingest() overwrites the device snapshot).
     */
    public void syncDevice(Long deviceId) {
        Device device = deviceRepository.findById(deviceId).orElse(null);
        if (device == null || device.getPlatformDeviceId() == null) return;

        Instant cursor = device.getLastTelemetrySyncedAt();

        // Phase 1: Collect all unprocessed records across pages
        List<ReportRecordPageResp.ReportRecord> toProcess = new ArrayList<>();
        int page = 1;
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
                if (cursor != null && !reportTime.isAfter(cursor)) continue;
                toProcess.add(record);
            }

            if (resp.getData().getRecords().size() < pageSize) break;
            page++;
        }

        if (toProcess.isEmpty()) return;

        // Phase 2: Sort ascending by reportTime (oldest first) so newest record's
        // snapshot values (gateway, rssi, snr) are the final ones after ingestion
        toProcess.sort(Comparator.comparing(r ->
                AgenticPlatformReportData.parseReportTime(r.getReportTime())));

        // Phase 3: Ingest each record in chronological order
        for (ReportRecordPageResp.ReportRecord record : toProcess) {
            Instant reportTime = AgenticPlatformReportData.parseReportTime(record.getReportTime());
            Map<String, Object> readings = AgenticPlatformReportData.toReadings(record);
            AgenticPlatformReportData.applyAccelerometerConversion(readings);
            telemetryIngestionService.ingest(deviceId, readings, reportTime, TelemetrySource.AGENTIC_PLATFORM);
        }

        log.debug("[PlatformSync] device {} synced {} records", deviceId, toProcess.size());
    }
}
