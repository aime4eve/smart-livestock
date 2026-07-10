package com.smartlivestock.docking.client;

import com.smartlivestock.docking.client.fallback.BladeLicenseFallback;
import com.smartlivestock.docking.dto.LicenseStatusResp;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

/**
 * Blade license lookup, url mode (no Nacos). open-platform-dev uses a distinct
 * Nacos service name for license ("hkt-blade-device-license-client"), so it may
 * deploy separately; here it gets its own base-url config.
 */
@FeignClient(
        name = "blade-license",
        url = "${blade.license.base-url}",
        path = "/feign/v1/device-license/control",
        configuration = BladeFeignConfig.class,
        fallbackFactory = BladeLicenseFallback.class
)
public interface BladeLicenseClient {

    @GetMapping("/by-sn")
    InternalResponse<LicenseStatusResp> getLicenseStatusBySn(@RequestParam("deviceSn") String deviceSn);
}
