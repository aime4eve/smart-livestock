package com.smartlivestock.iot.infrastructure.client.agenticplatform.client;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.fallback.AgenticPlatformHistoryDataFallback;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.ReportRecordPageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.TelemetryQueryReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.TelemetryResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

/**
 * Agentic-middle-platform telemetry + history data endpoints (url mode, no Nacos).
 * Verified against real platform at 172.22.4.17:8100 on 2026-07-07.
 */
@FeignClient(
        name = "agentic-platform-device-telemetry",
        url = "${agentic-platform.device.base-url}",
        configuration = AgenticPlatformFeignConfig.class,
        fallbackFactory = AgenticPlatformHistoryDataFallback.class
)
public interface AgenticPlatformHistoryDataClient {

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
