package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformHistoryDataClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth.AgenticPlatformGatewayTokenService;
import feign.codec.DecodeException;
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
 * <p>
 * Includes automatic token cache eviction + single retry when the platform returns
 * a token-expired response (which manifests as Feign DecodeException because the
 * platform sends a plain String in the data field instead of a page object).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AgenticPlatformTelemetrySyncJob {

    private final DeviceRepository deviceRepository;
    private final AgenticPlatformHistoryDataClient historyClient;
    private final TelemetryIngestionService telemetryIngestionService;
    private final AgenticPlatformGatewayTokenService gatewayTokenService;

    @Value("${agentic-platform.sync.page-size:100}")
    private int pageSize;

    /**
     * Sync a single device by its local deviceId.
     */
    public void syncDevice(Long deviceId) {
        Device device = deviceRepository.findById(deviceId).orElse(null);
        if (device == null || device.getPlatformDeviceId() == null) return;

        Instant cursor = device.getLastTelemetrySyncedAt();

        List<ReportRecordPageResp.ReportRecord> toProcess = new ArrayList<>();
        int page = 1;
        while (true) {
            InternalResponse<ReportRecordPageResp> resp;
            try {
                resp = queryReportRecordsWithTokenRetry(
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

        toProcess.sort(Comparator.comparing(r ->
                AgenticPlatformReportData.parseReportTime(r.getReportTime())));

        for (ReportRecordPageResp.ReportRecord record : toProcess) {
            Instant reportTime = AgenticPlatformReportData.parseReportTime(record.getReportTime());
            Map<String, Object> readings = AgenticPlatformReportData.toReadings(record);
            AgenticPlatformReportData.applyAccelerometerConversion(readings);
            telemetryIngestionService.ingest(deviceId, readings, reportTime, TelemetrySource.AGENTIC_PLATFORM);
        }

        log.debug("[PlatformSync] device {} synced {} records", deviceId, toProcess.size());
    }

    /**
     * Wraps report-record query with automatic token cache eviction on token expiry.
     * <p>
     * When the platform token expires, blade returns HTTP 200 with code=401 and a plain
     * String in data (the expired token echo). This causes Feign DecodeException because
     * it expects a page object. We catch that, evict the cached token (forcing
     * re-exchange), and retry once with a fresh token.
     */
    private InternalResponse<ReportRecordPageResp> queryReportRecordsWithTokenRetry(
            String platformDeviceId, int page, int pageSize) {
        try {
            return historyClient.queryReportRecords(platformDeviceId, page, pageSize);
        } catch (DecodeException e) {
            log.warn("[PlatformSync] token likely expired (Feign DecodeException), evicting cache and retrying");
            gatewayTokenService.evictAll();
            return historyClient.queryReportRecords(platformDeviceId, page, pageSize);
        }
    }
}
