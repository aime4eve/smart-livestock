package com.smartlivestock.iot.application.service;

import com.smartlivestock.iot.application.DeviceApplicationService;
import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.dto.DeviceDto;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

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
 * Tests device lifecycle (INVENTORY -> ACTIVE -> OFFLINE -> DECOMMISSIONED)
 * through the application service layer with mocked repository.
 */
@ExtendWith(MockitoExtension.class)
class DeviceApplicationServiceTest {

    @Mock
    private DeviceRepository deviceRepository;

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

    private Device createOfflineDevice() {
        Device device = createActiveDevice();
        device.markOffline();
        return device;
    }

    @Test
    @DisplayName("注册新设备")
    void shouldRegisterNewDevice() {
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> {
            Device d = inv.getArgument(0);
            d.setId(1L);
            return d;
        });

        DeviceDto result = service.registerDevice(
                new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L));

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
    @DisplayName("激活库存设备")
    void shouldActivateInventoryDevice() {
        Device device = createInventoryDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.activateDevice(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.ACTIVE);
    }

    @Test
    @DisplayName("激活离线设备")
    void shouldActivateOfflineDevice() {
        Device device = createOfflineDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.activateDevice(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.ACTIVE);
    }

    @Test
    @DisplayName("拒绝激活非 INVENTORY/OFFLINE 状态的设备")
    void shouldRejectActivateNonInventoryDevice() {
        Device device = createActiveDevice(); // already ACTIVE
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
    @DisplayName("将活跃设备标记为离线")
    void shouldMarkOfflineActiveDevice() {
        Device device = createActiveDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.markOffline(1L);

        ArgumentCaptor<Device> captor = ArgumentCaptor.forClass(Device.class);
        verify(deviceRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(DeviceStatus.OFFLINE);
    }

    @Test
    @DisplayName("拒绝标记库存设备为离线")
    void shouldRejectMarkOfflineInventoryDevice() {
        Device device = createInventoryDevice();
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> service.markOffline(1L))
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
