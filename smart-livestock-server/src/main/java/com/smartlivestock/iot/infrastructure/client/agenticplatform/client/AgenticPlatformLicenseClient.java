package com.smartlivestock.iot.infrastructure.client.agenticplatform.client;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.fallback.AgenticPlatformLicenseFallback;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.LicenseStatusResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * License lookup, url mode (no Nacos). May deploy separately, so it gets its own base-url config.
 */
@FeignClient(
        name = "agentic-platform-license",
        url = "${agentic-platform.license.base-url}",
        path = "/feign/v1/device-license/control",
        configuration = AgenticPlatformFeignConfig.class,
        fallbackFactory = AgenticPlatformLicenseFallback.class
)
public interface AgenticPlatformLicenseClient {

    @GetMapping("/by-sn")
    InternalResponse<LicenseStatusResp> getLicenseStatusBySn(@RequestParam("deviceSn") String deviceSn);
}
