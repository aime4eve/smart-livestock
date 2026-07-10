package com.ai.openapi.device.client.fallback;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.device.client.DeviceHistoryDataClient;
import com.ai.openapi.device.dto.internal.DeviceHistoryDataPageReq;
import com.ai.openapi.device.dto.internal.DeviceHistoryDataPageResp;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

@Component
public class DeviceHistoryDataFallback implements FallbackFactory<DeviceHistoryDataClient> {

    @Override
    public DeviceHistoryDataClient create(Throwable cause) {
        return new DeviceHistoryDataClient() {
            @Override
            public InternalResponse<DeviceHistoryDataPageResp> queryHistoryDataPage(
                    String deviceId, DeviceHistoryDataPageReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<DeviceHistoryDataPageResp> querySubDeviceHistoryDataPage(
                    String subDeviceId, DeviceHistoryDataPageReq request) {
                throw upstreamError(cause);
            }
        };
    }

    private OpenApiException upstreamError(Throwable cause) {
        return new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                ErrorCode.UPSTREAM_ERROR.getCode(), "设备历史数据服务暂时不可用", cause);
    }
}
