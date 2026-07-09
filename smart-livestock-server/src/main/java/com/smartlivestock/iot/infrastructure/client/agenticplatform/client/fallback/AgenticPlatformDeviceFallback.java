package com.smartlivestock.iot.infrastructure.client.agenticplatform.client.fallback;

import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformDeviceClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformServiceException;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceDetailReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceDetailResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceListReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationReq;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceTelemetryResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class AgenticPlatformDeviceFallback implements FallbackFactory<AgenticPlatformDeviceClient> {

    @Override
    public AgenticPlatformDeviceClient create(Throwable cause) {
        return new AgenticPlatformDeviceClient() {
            @Override
            public InternalResponse<DeviceRegistrationResp> registerDevice(DeviceRegistrationReq request) {
                throw new AgenticPlatformServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<DevicePageResp> pageDevices(DevicePageReq request) {
                throw new AgenticPlatformServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<DeviceDetailResp> getDeviceDetail(DeviceDetailReq request) {
                throw new AgenticPlatformServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(String deviceId) {
                throw new AgenticPlatformServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<List<DeviceDetailResp>> listDevices(DeviceListReq request) {
                throw new AgenticPlatformServiceException("Device service unavailable", cause);
            }
        };
    }
}
