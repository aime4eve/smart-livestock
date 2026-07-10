package com.smartlivestock.docking.client;

import com.smartlivestock.docking.client.fallback.BladeHistoryDataFallback;
import com.smartlivestock.docking.dto.ReportRecordPageResp;
import com.smartlivestock.docking.dto.TelemetryQueryReq;
import com.smartlivestock.docking.dto.TelemetryResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

/**
 * Blade telemetry + history data endpoints (url mode, no Nacos).
 * Verified against real blade at 172.22.4.17:8100 on 2026-07-07.
 *
 * Real endpoints:
 *   /feign/v1/device/telemetry/history/latest  (POST) - latest telemetry snapshot
 *   /feign/v1/device/telemetry/history/query   (POST) - paginated history query
 *   /device/report-record/page                 (GET)  - raw uplink records with decodeData
 */
@FeignClient(
        name = "blade-device-telemetry",
        url = "${blade.device.base-url}",
        configuration = BladeFeignConfig.class,
        fallbackFactory = BladeHistoryDataFallback.class
)
public interface BladeHistoryDataClient {

    @PostMapping("/feign/v1/device/telemetry/history/latest")
    InternalResponse<List<TelemetryResp>> queryLatest(@RequestBody TelemetryQueryReq request);

    @PostMapping("/feign/v1/device/telemetry/history/query")
    InternalResponse<List<TelemetryResp>> queryHistory(@RequestBody TelemetryQueryReq request);

    @GetMapping("/device/report-record/page")
    InternalResponse<ReportRecordPageResp> queryReportRecords(
            @RequestParam("deviceId") String deviceId,
            @RequestParam("current") Integer current,
            @RequestParam("size") Integer size);
}
