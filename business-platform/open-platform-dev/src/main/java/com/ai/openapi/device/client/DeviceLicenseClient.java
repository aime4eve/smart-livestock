package com.ai.openapi.device.client;

import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.common.config.FeignConfig;
import com.ai.openapi.device.client.fallback.DeviceLicenseFallback;
import com.ai.openapi.device.dto.internal.LicenseStatusResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(
        name = "hkt-blade-device-license-client",
        path = "/feign/v1/device-license/control",
        configuration = FeignConfig.class,
        fallbackFactory = DeviceLicenseFallback.class
)
public interface DeviceLicenseClient {

    @GetMapping("/by-sn")
    InternalResponse<LicenseStatusResp> getLicenseStatusBySn(@RequestParam("deviceSn") String deviceSn);
}
