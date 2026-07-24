package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformHistoryDataClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.oauth.AgenticPlatformGatewayTokenService;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
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

    @Value("${agentic-platform.oauth2.service-user-id:2074385063398711296}")
    private String serviceUserId;

    /**
     * Sync a single device by its local deviceId.
     */
    public void syncDevice(Long deviceId) {
        Device device = deviceRepository.findById(deviceId).orElse(null);
        if (device == null) {
            log.warn("[PlatformSync] device {} not found, skipping", deviceId);
            return;
        }
        if (device.getPlatformDeviceId() == null) {
            log.warn("[PlatformSync] device {} has no platformDeviceId, skipping", deviceId);
            return;
        }

        String platformDeviceId = String.valueOf(device.getPlatformDeviceId());
        Instant cursor = device.getLastTelemetrySyncedAt();
        log.info("[PlatformSync] device {} (platformId={}) sync start, cursor={}", deviceId, platformDeviceId, cursor);

        List<ReportRecordPageResp.ReportRecord> toProcess = new ArrayList<>();
        int page = 1;
        while (true) {
            InternalResponse<ReportRecordPageResp> resp;
            try {
                resp = queryReportRecordsWithTokenRetry(platformDeviceId, page, pageSize);
            } catch (Exception e) {
                log.error("[PlatformSync] device {} (platformId={}) report-record fetch failed: {}",
                        deviceId, platformDeviceId, e.getMessage());
                throw e;
            }

            if (resp == null) {
                log.warn("[PlatformSync] device {} (platformId={}) page {} returned null response",
                        deviceId, platformDeviceId, page);
                break;
            }
            if (!resp.isOk()) {
                log.warn("[PlatformSync] device {} (platformId={}) page {} returned code={} msg={}",
                        deviceId, platformDeviceId, page, resp.getCode(), resp.getMsg());
                break;
            }
            if (resp.getData() == null || resp.getData().getRecords() == null
                    || resp.getData().getRecords().isEmpty()) {
                log.info("[PlatformSync] device {} (platformId={}) page {} returned empty records (total={})",
                        deviceId, platformDeviceId, page,
                        resp.getData() != null ? resp.getData().getTotal() : "null");
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

        if (toProcess.isEmpty()) {
            log.info("[PlatformSync] device {} (platformId={}) no new records to process", deviceId, platformDeviceId);
            return;
        }

        toProcess.sort(Comparator.comparing(r ->
                AgenticPlatformReportData.parseReportTime(r.getReportTime())));

        int ingested = 0;
        int skipped = 0;
        for (ReportRecordPageResp.ReportRecord record : toProcess) {
           Instant reportTime = AgenticPlatformReportData.parseReportTime(record.getReportTime());
           Map<String, Object> readings = AgenticPlatformReportData.toReadings(record);
           AgenticPlatformReportData.applyAccelerometerConversion(readings);
           // Validate GPS values to prevent numeric overflow (precision 10,7 = max 999.x)
           Object latObj = readings.get("latitude");
           Object lngObj = readings.get("longitude");
           if (latObj instanceof BigDecimal lat && lat.abs().compareTo(BigDecimal.valueOf(1000)) >= 0) {
               log.warn("[PlatformSync] device {} has out-of-range latitude={}, clamping", deviceId, lat);
               readings.put("latitude", null);
           }
           if (lngObj instanceof BigDecimal lng && lng.abs().compareTo(BigDecimal.valueOf(1000)) >= 0) {
               log.warn("[PlatformSync] device {} has out-of-range longitude={}, clamping", deviceId, lng);
               readings.put("longitude", null);
           }
           try {
               telemetryIngestionService.ingest(deviceId, readings, reportTime, TelemetrySource.AGENTIC_PLATFORM);
               ingested++;
           } catch (DataIntegrityViolationException e) {
               // Skip bad record so the sync cursor still advances.
               log.error("[PlatformSync] device {} skipping bad record (rt={}): readings={} err={}",
                       deviceId, reportTime, readings, e.getMessage());
               skipped++;
           }
        }

        log.info("[PlatformSync] device {} (platformId={}) synced {} records (ingested={}, skipped={})",
                deviceId, platformDeviceId, toProcess.size(), ingested, skipped);
    }

    /**
     * Wraps report-record query with automatic token cache eviction on token expiry.
     * <p>
     * When the platform token expires, blade returns HTTP 200 with code=401 and a plain
     * String in data (the expired token echo). This causes Feign DecodeException because
     * it expects a page object. We catch that, evict the cached token (forcing
     * re-exchange), and retry once with a fresh token.
     * <p>
     * Uses evictToken(serviceUserId) instead of evictAll() to avoid a thundering herd:
     * when 20 concurrent workers all get DecodeException simultaneously, evictAll()
     * clears the entire cache and each worker independently re-fetches a token,
     * creating cascading evictions. evictToken() achieves the same result (there is
     * only one service userId) without the ConcurrentHashMap-wide churn.
     */
    private InternalResponse<ReportRecordPageResp> queryReportRecordsWithTokenRetry(
            String platformDeviceId, int page, int pageSize) {
        try {
            return historyClient.queryReportRecords(platformDeviceId, page, pageSize);
        } catch (DecodeException e) {
            log.warn("[PlatformSync] token likely expired for platformId={} page={} (Feign DecodeException), evicting and retrying",
                    platformDeviceId, page);
            gatewayTokenService.evictToken(serviceUserId);
            return historyClient.queryReportRecords(platformDeviceId, page, pageSize);
        }
    }
}
