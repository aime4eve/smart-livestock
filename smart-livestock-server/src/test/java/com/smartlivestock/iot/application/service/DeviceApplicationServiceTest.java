package com.smartlivestock.iot.application.service;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformDeviceClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.client.AgenticPlatformLicenseClient;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DevicePageResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.DeviceRegistrationResp;
import com.smartlivestock.iot.infrastructure.client.agenticplatform.dto.InternalResponse;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit-level integration test for DeviceApplicationService.
 * <p>
 * Tests device lifecycle (INVENTORY -> ACTIVE -> DECOMMISSIONED)
 * through the application service layer with mocked repository + platform clients.
 */
@ExtendWith(MockitoExtension.class)
class DeviceApplicationServiceTest {

    @Mock
    private DeviceRepository deviceRepository;

    @Mock
    private AgenticPlatformDeviceClient platformDeviceClient;

    @Mock
    private AgenticPlatformLicenseClient platformLicenseClient;

    @InjectMocks
    private DeviceApplicationService service;

    private Device createInventoryDevice() {
        Device device = new Device(1L, "DEV-001", DeviceType.TRACKER, "AABBCCDD");
        device.setId(1L);
        return device;
    }

    private Device createActiveDevice() {
        Device device = createInventoryDevice();
        device.activate();
        return device;
    }

    private Device createDecommissionedDevice() {
        Device device = createActiveDevice();
        device.decommission();
        return device;
    }

    private InternalResponse<DevicePageResp> emptyPage() {
        DevicePageResp page = new DevicePageResp();
        page.setTotal(0L);
        page.setRecords(Collections.emptyList());
        InternalResponse<DevicePageResp> resp = new InternalResponse<>();
        resp.setSuccess(true);
        resp.setCode(200);
        resp.setData(page);
        return resp;
    }

    private InternalResponse<DeviceRegistrationResp> registered(Long deviceId) {
        DeviceRegistrationResp data = new DeviceRegistrationResp();
        data.setDeviceId(String.valueOf(deviceId));
        InternalResponse<DeviceRegistrationResp> resp = new InternalResponse<>();
        resp.setSuccess(true);
        resp.setCode(200);
        resp.setData(data);
        return resp;
    }

    @Test
    @DisplayName("注册新设备（无 SN/EUI → 平台注册跳过，保持 INVENTORY）")
    void shouldRegisterNewDevice() {
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> {
            Device d = inv.getArgument(0);
            d.setId(1L);
            return d;
        });

        // No serialNo, no devEui → platform registration has no EUI and throws,
        // caught inside registerDevice → device stays INVENTORY.
        DeviceDto result = service.registerDevice(
                new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L, null, null));

        assertThat(result.deviceCode()).isEqualTo("DEV-001");
        assertThat(result.deviceType()).isEqualTo("TRACKER");
        assertThat(result.status()).isEqualTo("INVENTORY");
        assertThat(result.tenantId()).isEqualTo(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        Device saved = captor.getValue();
        assertThat(saved.getStatus()).isEqualTo(DeviceStatus.INVENTORY);
        assertThat(saved.getTenantId()).isEqualTo(1L);
        assertThat(saved.getDeviceCode()).isEqualTo("DEV-001");
    }

    @Test
    @DisplayName("激活库存设备（平台注册成功 → ACTIVE）")
    void shouldActivateInventoryDevice() {
        Device device = createInventoryDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));
        when(platformDeviceClient.pageDevices(any())).thenReturn(emptyPage());
        when(platformDeviceClient.registerDevice(any())).thenReturn(registered(100L));

        DeviceDto result = service.activateDevice(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.ACTIVE);
        assertThat(captor.getValue().getPlatformDeviceId()).isEqualTo(100L);
        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.platformDeviceId()).isEqualTo(100L);
    }

    @Test
    @DisplayName("已激活设备重复激活（幂等，直接返回）")
    void shouldActivateActiveDeviceIdempotently() {
        Device device = createActiveDevice();
        device.setPlatformDeviceId(100L);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        DeviceDto result = service.activateDevice(1L);

        assertThat(result.status()).isEqualTo("ACTIVE");
        // No platform call, no save for an already-active device
        verify(platformDeviceClient, never()).pageDevices(any());
        verify(platformDeviceClient, never()).registerDevice(any());
        verify(deviceRepository, never()).save(any());
    }

    @Test
    @DisplayName("拒绝激活 DECOMMISSIONED 状态的设备")
    void shouldRejectActivateDecommissionedDevice() {
        Device device = createDecommissionedDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> service.activateDevice(1L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });

        verify(deviceRepository, never()).save(any());
    }

    @Test
    @DisplayName("停用活跃设备")
    void shouldDecommissionActiveDevice() {
        Device device = createActiveDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.decommissionDevice(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.DECOMMISSIONED);
    }

    @Test
    @DisplayName("设备不存在时，抛出 RESOURCE_NOT_FOUND")
    void shouldThrowResourceNotFoundForMissingDevice() {
        when(deviceRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.activateDevice(999L))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
                });
    }
}
