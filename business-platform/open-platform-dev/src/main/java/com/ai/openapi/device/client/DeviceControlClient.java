package com.ai.openapi.device.client;

import com.ai.openapi.common.config.FeignConfig;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.device.client.fallback.DeviceControlFallback;
import com.ai.openapi.device.dto.internal.BatchCmdDownResp;
import com.ai.openapi.device.dto.internal.BusinessCmdDownReq;
import com.ai.openapi.device.dto.internal.DeviceControlRecordRespDto;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;

@FeignClient(
        name = "hkt-blade-device",
        contextId = "hktBladeDeviceControl",
        path = "/feign/v1/device/control",
        configuration = FeignConfig.class,
        fallbackFactory = DeviceControlFallback.class
)
public interface DeviceControlClient {

    @PostMapping("/businessCmdDown")
    InternalResponse<BatchCmdDownResp> businessCmdDown(@RequestBody BusinessCmdDownReq request);

    /**
     * 按记录 ID 批量查询控制记录（body 为字符串数组）。
     */
    @PostMapping("/record/queryControlRecordByIds")
    InternalResponse<List<DeviceControlRecordRespDto>> queryControlRecordByIds(@RequestBody List<String> recordIds);
}
