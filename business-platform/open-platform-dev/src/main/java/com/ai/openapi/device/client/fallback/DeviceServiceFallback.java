package com.ai.openapi.device.client.fallback;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.device.client.DeviceServiceClient;
import com.ai.openapi.device.dto.internal.*;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DeviceServiceFallback implements FallbackFactory<DeviceServiceClient> {

    @Override
    public DeviceServiceClient create(Throwable cause) {
        return new DeviceServiceClient() {
            @Override
            public InternalResponse<DeviceRegistrationResp> registerDevice(DeviceRegistrationReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<DevicePageResp> pageDevices(DevicePageReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<List<DeviceDetailResp>> listDevices(DeviceListReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<DeviceDetailResp> getDeviceDetail(DeviceDetailReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<Boolean> updateDeviceInfo(DeviceUpdateReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<Boolean> removeDevice(DeviceRemoveReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<List<DeviceDetailResp>> batchGetDeviceDetails(BatchDeviceDetailReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(String deviceId) {
                throw upstreamError(cause);
            }
        };
    }

    private OpenApiException upstreamError(Throwable cause) {
        return new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                ErrorCode.UPSTREAM_ERROR.getCode(), "设备服务暂时不可用", cause);
    }
}
