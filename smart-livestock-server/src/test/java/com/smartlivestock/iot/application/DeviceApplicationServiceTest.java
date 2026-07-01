package com.smartlivestock.iot.application;

import com.smartlivestock.iot.application.command.RegisterDeviceCommand;
import com.smartlivestock.iot.application.command.UpdateDeviceCommand;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
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
class DeviceApplicationServiceTest {

    @Mock
    private DeviceRepository deviceRepository;

    @InjectMocks
    private DeviceApplicationService service;

    @Test
    void shouldRegisterDeviceWithDevEui() {
        when(deviceRepository.findByDeviceCode("DEV-001")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> {
            Device d = inv.getArgument(0);
            d.setId(1L);
            return d;
        });

        var cmd = new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L, "AABBCCDDEEFF0011");
        var result = service.registerDevice(cmd);

        assertThat(result.deviceCode()).isEqualTo("DEV-001");
        assertThat(result.devEui()).isEqualTo("AABBCCDDEEFF0011");
    }

    @Test
    void shouldRejectDuplicateDeviceCode() {
        Device existing = new Device();
        existing.setId(99L);
        when(deviceRepository.findByDeviceCode("DEV-001")).thenReturn(Optional.of(existing));

        var cmd = new RegisterDeviceCommand("DEV-001", DeviceType.TRACKER, 1L, null);
        assertThatThrownBy(() -> service.registerDevice(cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }

    @Test
    void shouldUpdateDeviceCodeAndDevEui() {
        Device existing = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        existing.setStatus(DeviceStatus.ACTIVE);
        existing.setId(10L);
        when(deviceRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(deviceRepository.findByDeviceCode("DEV-002")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        var cmd = new UpdateDeviceCommand("DEV-002", "AABBCCDDEEFF0022");
        var result = service.updateDevice(10L, cmd);

        assertThat(result.deviceCode()).isEqualTo("DEV-002");
        assertThat(result.devEui()).isEqualTo("AABBCCDDEEFF0022");
    }

    @Test
    void shouldRejectUpdateWithDuplicateCode() {
        Device existing = new Device(1L, "DEV-001", DeviceType.TRACKER, null);
        existing.setId(10L);
        Device other = new Device(2L, "DEV-002", DeviceType.CAPSULE, null);
        other.setId(20L);

        when(deviceRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(deviceRepository.findByDeviceCode("DEV-002")).thenReturn(Optional.of(other));

        var cmd = new UpdateDeviceCommand("DEV-002", null);
        assertThatThrownBy(() -> service.updateDevice(10L, cmd))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.DUPLICATE_RESOURCE);
                });
    }
}
