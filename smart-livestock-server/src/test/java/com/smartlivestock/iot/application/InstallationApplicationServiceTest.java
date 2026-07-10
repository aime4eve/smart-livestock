package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.InstallDeviceCommand;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InstallationApplicationServiceTest {

    @Mock
    private InstallationRepository installationRepository;

    @Mock
    private DeviceRepository deviceRepository;

    @InjectMocks
    private InstallationApplicationService service;

    @Test
    void shouldRejectInstallOnNonActiveDevice() {
        Device device = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.INVENTORY);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));

        var cmd = new InstallDeviceCommand(1L, 10L, 100L);
        assertThatThrownBy(() -> service.install(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DEVICE_NOT_ACTIVE);
                });
    }

    @Test
    void shouldRejectInstallAlreadyInstalledDevice() {
        Device device = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.ACTIVE);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        Installation existing = new Installation(1L, 10L, 100L);
        existing.setId(50L);
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.of(existing));

        var cmd = new InstallDeviceCommand(1L, 20L, 100L);
        assertThatThrownBy(() -> service.install(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    void shouldRejectInstallDuplicateDeviceType() {
        Device device = new Device(1L, "DEV-002", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.ACTIVE);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.empty());
        Installation existing = new Installation(2L, 10L, 100L);
        existing.setId(50L);
        when(installationRepository.findActiveByLivestockIdAndDeviceType(10L, DeviceType.TRACKER))
                .thenReturn(Optional.of(existing));

        var cmd = new InstallDeviceCommand(1L, 10L, 100L);
        assertThatThrownBy(() -> service.install(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                });
    }

    @Test
    void shouldAllowInstallDifferentDeviceTypes() {
        Device gps = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        gps.setStatus(DeviceStatus.ACTIVE);
        when(deviceRepository.findById(1L)).thenReturn(Optional.of(gps));
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.empty());
        when(installationRepository.findActiveByLivestockIdAndDeviceType(10L, DeviceType.TRACKER))
                .thenReturn(Optional.empty());
        when(installationRepository.save(any(Installation.class))).thenAnswer(inv -> {
            Installation i = inv.getArgument(0);
            i.setId(1L);
            return i;
        });

        var cmd = new InstallDeviceCommand(1L, 10L, 100L);
        var result = service.install(cmd);

        assertThat(result.deviceId()).isEqualTo(1L);
        assertThat(result.livestockId()).isEqualTo(10L);
        assertThat(result.active()).isTrue();
    }
}
