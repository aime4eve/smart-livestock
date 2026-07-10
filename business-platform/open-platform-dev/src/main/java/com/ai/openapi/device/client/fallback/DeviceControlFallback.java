package com.ai.openapi.device.client.fallback;

import com.ai.openapi.common.exception.ErrorCode;
import com.ai.openapi.common.exception.OpenApiException;
import com.ai.openapi.common.feign.InternalResponse;
import com.ai.openapi.device.client.DeviceControlClient;
import com.ai.openapi.device.dto.internal.BatchCmdDownResp;
import com.ai.openapi.device.dto.internal.BusinessCmdDownReq;
import com.ai.openapi.device.dto.internal.DeviceControlRecordRespDto;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DeviceControlFallback implements FallbackFactory<DeviceControlClient> {

    @Override
    public DeviceControlClient create(Throwable cause) {
        return new DeviceControlClient() {
            @Override
            public InternalResponse<BatchCmdDownResp> businessCmdDown(BusinessCmdDownReq request) {
                throw upstreamError(cause);
            }

            @Override
            public InternalResponse<List<DeviceControlRecordRespDto>> queryControlRecordByIds(List<String> recordIds) {
                throw upstreamError(cause);
            }
        };
    }

    private OpenApiException upstreamError(Throwable cause) {
        return new OpenApiException(ErrorCode.UPSTREAM_ERROR.getHttpStatus(),
                ErrorCode.UPSTREAM_ERROR.getCode(), "设备控制服务暂时不可用", cause);
    }
}
