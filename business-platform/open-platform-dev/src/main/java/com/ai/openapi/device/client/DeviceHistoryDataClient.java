package com.ai.openapi.device.client;

import com.ai.openapi.common.config.FeignConfig;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.device.client.fallback.DeviceHistoryDataFallback;
import com.ai.openapi.device.dto.internal.DeviceHistoryDataPageReq;
import com.ai.openapi.device.dto.internal.DeviceHistoryDataPageResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@FeignClient(
        name = "hkt-blade-device",
        contextId = "hktBladeDeviceHistoryData",
        path = "/feign/v1/device/history/data",
        configuration = FeignConfig.class,
        fallbackFactory = DeviceHistoryDataFallback.class
)
public interface DeviceHistoryDataClient {

    @PostMapping("/query-list-page/{deviceId}")
    InternalResponse<DeviceHistoryDataPageResp> queryHistoryDataPage(
            @PathVariable("deviceId") String deviceId,
            @RequestBody DeviceHistoryDataPageReq request);

    @PostMapping("/query-sub-device-list-page/{subDeviceId}")
    InternalResponse<DeviceHistoryDataPageResp> querySubDeviceHistoryDataPage(
            @PathVariable("subDeviceId") String subDeviceId,
            @RequestBody DeviceHistoryDataPageReq request);
}
