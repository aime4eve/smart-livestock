package com.smartlivestock.docking.client.fallback;

import com.smartlivestock.docking.client.BladeDeviceServiceClient;
import com.smartlivestock.docking.client.DeviceDetailReq;
import com.smartlivestock.docking.client.DeviceListReq;
import com.smartlivestock.docking.client.InternalResponse;
import com.smartlivestock.docking.dto.DeviceDetailResp;
import com.smartlivestock.docking.dto.DevicePageReq;
import com.smartlivestock.docking.dto.DevicePageResp;
import com.smartlivestock.docking.dto.DeviceRegistrationReq;
import com.smartlivestock.docking.dto.DeviceRegistrationResp;
import com.smartlivestock.docking.dto.DeviceTelemetryResp;
import com.smartlivestock.docking.service.BladeServiceException;
import org.springframework.cloud.openfeign.FallbackFactory;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class BladeDeviceServiceFallback implements FallbackFactory<BladeDeviceServiceClient> {

    @Override
    public BladeDeviceServiceClient create(Throwable cause) {
        return new BladeDeviceServiceClient() {
            @Override
            public InternalResponse<DeviceRegistrationResp> registerDevice(DeviceRegistrationReq request) {
                throw new BladeServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<DevicePageResp> pageDevices(DevicePageReq request) {
                throw new BladeServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<DeviceDetailResp> getDeviceDetail(DeviceDetailReq request) {
                throw new BladeServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<DeviceTelemetryResp> getDeviceDetailWithTelemetry(String deviceId) {
                throw new BladeServiceException("Device service unavailable", cause);
            }
            @Override
            public InternalResponse<List<DeviceDetailResp>> listDevices(DeviceListReq request) {
                throw new BladeServiceException("Device service unavailable", cause);
            }
        };
    }
}
