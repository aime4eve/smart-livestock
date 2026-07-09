package com.smartlivestock.iot.infrastructure.client.agenticplatform.client.fallback;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformLicenseClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformServiceException;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.LicenseStatusResp;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

@Component
public class AgenticPlatformLicenseFallback implements FallbackFactory<AgenticPlatformLicenseClient> {

    @Override
    public AgenticPlatformLicenseClient create(Throwable cause) {
        return deviceSn -> {
            throw new AgenticPlatformServiceException("License service unavailable", cause);
        };
    }
}
