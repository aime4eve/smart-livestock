package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class DeviceTest {

    private Device createDevice() {
        return new Device(
            1L,                 // tenantId
            "DEV-001",          // deviceCode
            DeviceType.TRACKER, // deviceType
            "0102030405060708"  // devEui
        );
    }

    @Test
    void shouldCreateDeviceWithInventoryStatus() {
        Device device = createDevice();

        assertThat(device.getTenantId()).isEqualTo(1L);
        assertThat(device.getDeviceCode()).isEqualTo("DEV-001");
        assertThat(device.getDeviceType()).isEqualTo(DeviceType.TRACKER);
        assertThat(device.getDevEui()).isEqualTo("0102030405060708");
        assertThat(device.getStatus()).isEqualTo(DeviceStatus.INVENTORY);
        assertThat(device.getRuntimeStatus()).isNull();
        assertThat(device.getBatteryLevel()).isNull();
        assertThat(device.getFirmwareVersion()).isNull();
        assertThat(device.getLastOnlineAt()).isNull();
    }

    @Test
    void shouldTransitionInventoryToActive() {
        Device device = createDevice();

        device.activate();

        assertThat(device.getStatus()).isEqualTo(DeviceStatus.ACTIVE);
        assertThat(device.getDomainEvents()).hasSize(1);
        assertThat(device.getDomainEvents().get(0)).isInstanceOf(com.smartlivestock.iot.domain.event.DeviceActivatedEvent.class);
    }

    @Test
    void shouldTransitionActiveToDecommissioned() {
        Device device = createDevice();
        device.activate();

        device.decommission();

        assertThat(device.getStatus()).isEqualTo(DeviceStatus.DECOMMISSIONED);
    }

    @Test
    void shouldRejectActivateWhenAlreadyActive() {
        Device device = createDevice();
        device.activate();

        assertThatThrownBy(() -> device.activate())
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("INVENTORY");
    }

    @Test
    void shouldRejectActivateFromDecommissioned() {
        Device device = createDevice();
        device.activate();
        device.decommission();

        assertThatThrownBy(() -> device.activate())
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("INVENTORY");
    }

    @Test
    void shouldRejectDecommissionFromInventory() {
        Device device = createDevice();

        assertThatThrownBy(device::decommission)
            .isInstanceOf(ApiException.class)
            .hasMessageContaining("ACTIVE");
    }

    @Test
    void shouldRejectDecommissionWhenAlreadyDecommissioned() {
        Device device = createDevice();
        device.activate();
        device.decommission();

        assertThatThrownBy(device::decommission)
            .isInstanceOf(ApiException.class);
    }

    @Test
    void shouldUpdateRuntimeStatus() {
        Device device = createDevice();

        device.updateRuntimeStatus("online", 85, "1.2.3");

        assertThat(device.getRuntimeStatus()).isEqualTo("online");
        assertThat(device.getBatteryLevel()).isEqualTo(85);
        assertThat(device.getFirmwareVersion()).isEqualTo("1.2.3");
        assertThat(device.getLastOnlineAt()).isNotNull();
    }

    @Test
    void shouldRestoreSoftDeletedDeviceToInventory() {
        Device device = createDevice();
        device.activate();
        device.setDeletedAt(java.time.Instant.now());

        device.restore();

        assertThat(device.getDeletedAt()).isNull();
        assertThat(device.getStatus()).isEqualTo(DeviceStatus.INVENTORY);
    }
}
