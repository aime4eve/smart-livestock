package com.ai.openapi.device.client.fallback;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.device.client.DeviceLicenseClient;
import com.ai.openapi.device.dto.internal.LicenseStatusResp;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

@Component
public class DeviceLicenseFallback implements FallbackFactory<DeviceLicenseClient> {

    @Override
    public DeviceLicenseClient create(Throwable cause) {
        return new DeviceLicenseClient() {
            @Override
            public InternalResponse<LicenseStatusResp> getLicenseStatusBySn(String deviceSn) {
                throw new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                        ErrorCode.UPSTREAM_ERROR.getCode(), "License 服务暂时不可用", cause);
            }
        };
    }
}
