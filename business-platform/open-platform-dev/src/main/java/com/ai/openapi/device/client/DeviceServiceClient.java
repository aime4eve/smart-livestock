package com.ai.openapi.device.client;

import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.common.config.FeignConfig;
import com.ai.openapi.device.client.fallback.DeviceServiceFallback;
import com.ai.openapi.device.dto.internal.*;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(
        name = "hkt-blade-device",
        contextId = "hktBladeDeviceLifecycle",
        path = "/feign/v1/device/lifecycle",
        configuration = FeignConfig.class,
        fallbackFactory = DeviceServiceFallback.class
)
public interface DeviceServiceClient {

    @PostMapping("/registerDevice")
    InternalResponse<DeviceRegistrationResp> registerDevice(@RequestBody DeviceRegistrationReq request);

    @PostMapping("/pageDevices")
    InternalResponse<DevicePageResp> pageDevices(@RequestBody DevicePageReq request);

    @PostMapping("/listDevices")
    InternalResponse<List<DeviceDetailResp>> listDevices(@RequestBody DeviceListReq request);

    @PostMapping("/getDeviceDetail")
    InternalResponse<DeviceDetailResp> getDeviceDetail(@RequestBody DeviceDetailReq request);

    @PostMapping("/updateDeviceInfo")
    InternalResponse<Boolean> updateDeviceInfo(@RequestBody DeviceUpdateReq request);

    @PostMapping("/removeDevice")
    InternalResponse<Boolean> removeDevice(@RequestBody DeviceRemoveReq request);

    @PostMapping("/batchGetDeviceDetails")
    InternalResponse<List<DeviceDetailResp>> batchGetDeviceDetails(@RequestBody BatchDeviceDetailReq request);

    @GetMapping("/getDeviceDetailWithTelemetry")
    InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(@RequestParam("deviceId") String deviceId);
}
