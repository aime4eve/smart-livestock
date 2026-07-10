package com.smartlivestock.docking.client;

import com.smartlivestock.docking.client.fallback.BladeDeviceServiceFallback;
import com.smartlivestock.docking.dto.DeviceDetailResp;
import com.smartlivestock.docking.dto.DevicePageReq;
import com.smartlivestock.docking.dto.DevicePageResp;
import com.smartlivestock.docking.dto.DeviceRegistrationReq;
import com.smartlivestock.docking.dto.DeviceRegistrationResp;
import com.smartlivestock.docking.dto.DeviceTelemetryResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * Blade device lifecycle endpoints (url mode, no Nacos).
 * Verified against real blade at 172.22.4.17:8100 on 2026-07-07.
 */
@FeignClient(
        name = "blade-device-lifecycle",
        url = "${blade.device.base-url}",
        path = "/feign/v1/device/lifecycle",
        configuration = BladeFeignConfig.class,
        fallbackFactory = BladeDeviceServiceFallback.class
)
public interface BladeDeviceServiceClient {

    @PostMapping("/registerDevice")
    InternalResponse<DeviceRegistrationResp> registerDevice(@RequestBody DeviceRegistrationReq request);

    @PostMapping("/pageDevices")
    InternalResponse<DevicePageResp> pageDevices(@RequestBody DevicePageReq request);

    @PostMapping("/getDeviceDetail")
    InternalResponse<DeviceDetailResp> getDeviceDetail(@RequestBody DeviceDetailReq request);

    @GetMapping("/getDeviceDetailWithTelemetry")
    InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(@RequestParam("deviceId") String deviceId);

    @PostMapping("/listDevices")
    InternalResponse<java.util.List<DeviceDetailResp>> listDevices(@RequestBody DeviceListReq request);
}
