package com.smartlivestock.iot.infrastructure.client.agenticplatform.client;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.fallback.AgenticPlatformDeviceFallback;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceDetailReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceDetailResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceListReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceTelemetryResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

/**
 * Agentic-middle-platform device lifecycle endpoints (url mode, no Nacos).
 * Verified against real platform at 172.22.4.17:8100.
 */
@FeignClient(
        name = "agentic-platform-device-lifecycle",
        url = "${agentic-platform.device.base-url}",
        path = "/feign/v1/device/lifecycle",
        configuration = AgenticPlatformFeignConfig.class,
        fallbackFactory = AgenticPlatformDeviceFallback.class
)
public interface AgenticPlatformDeviceClient {

    @PostMapping("/registerDevice")
    InternalResponse<DeviceRegistrationResp> registerDevice(@RequestBody DeviceRegistrationReq request);

    @PostMapping("/pageDevices")
    InternalResponse<DevicePageResp> pageDevices(@RequestBody DevicePageReq request);

    @PostMapping("/getDeviceDetail")
    InternalResponse<DeviceDetailResp> getDeviceDetail(@RequestBody DeviceDetailReq request);

    @GetMapping("/getDeviceDetailWithTelemetry")
    InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(@RequestParam("deviceId") String deviceId);

    @PostMapping("/listDevices")
    InternalResponse<List<DeviceDetailResp>> listDevices(@RequestBody DeviceListReq request);
}
