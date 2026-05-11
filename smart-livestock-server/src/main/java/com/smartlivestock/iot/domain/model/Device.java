package com.smartlivestock.iot.domain.model;

import com.smartlivestock.iot.domain.event.DeviceActivatedEvent;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;

import java.time.Instant;

/**
 * Device aggregate root representing an IoT device in the system.
 * <p>
 * Status machine: INVENTORY → ACTIVE → OFFLINE → DECOMMISSIONED
 * <ul>
 *   <li>Only INVENTORY or OFFLINE can activate()</li>
 *   <li>Only ACTIVE can markOffline()</li>
 *   <li>Only ACTIVE or OFFLINE can decommission()</li>
 * </ul>
 * Runtime status (online/offline/low_battery) is updated independently via heartbeat.
 */
public class Device extends AggregateRoot {

    private Long tenantId;
    private String deviceCode;
    private DeviceType deviceType;
    private DeviceStatus status;
    private String runtimeStatus;
    private Integer batteryLevel;
    private String firmwareVersion;
    private String devEui;
    private Instant lastOnlineAt;

    public Device() {
        this.status = DeviceStatus.INVENTORY;
    }

    public Device(Long tenantId, String deviceCode, DeviceType deviceType, String devEui) {
        this.tenantId = tenantId;
        this.deviceCode = deviceCode;
        this.deviceType = deviceType;
        this.devEui = devEui;
        this.status = DeviceStatus.INVENTORY;
    }

    /**
     * Activate this device. Only INVENTORY or OFFLINE devices can be activated.
     *
     * @throws ApiException (STATE_CONFLICT) if device is not in INVENTORY or OFFLINE status
     */
    public void activate() {
        if (status != DeviceStatus.INVENTORY && status != DeviceStatus.OFFLINE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device must be in INVENTORY or OFFLINE status to activate, current: " + status);
        }
        this.status = DeviceStatus.ACTIVE;
        registerEvent(new DeviceActivatedEvent(getId(), deviceCode));
    }

    /**
     * Mark this device as offline. Only ACTIVE devices can be marked offline.
     *
     * @throws ApiException (STATE_CONFLICT) if device is not in ACTIVE status
     */
    public void markOffline() {
        if (status != DeviceStatus.ACTIVE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device must be in ACTIVE status to mark offline, current: " + status);
        }
        this.status = DeviceStatus.OFFLINE;
    }

    /**
     * Decommission this device. Only ACTIVE or OFFLINE devices can be decommissioned.
     *
     * @throws ApiException (STATE_CONFLICT) if device is not in ACTIVE or OFFLINE status
     */
    public void decommission() {
        if (status != DeviceStatus.ACTIVE && status != DeviceStatus.OFFLINE) {
            throw new ApiException(ErrorCode.STATE_CONFLICT,
                "Device must be in ACTIVE or OFFLINE status to decommission, current: " + status);
        }
        this.status = DeviceStatus.DECOMMISSIONED;
    }

    /**
     * Update runtime status from heartbeat telemetry.
     *
     * @param runtimeStatus online, offline, low_battery
     * @param batteryLevel  battery percentage 0-100
     * @param firmwareVersion current firmware version
     */
    public void updateRuntimeStatus(String runtimeStatus, Integer batteryLevel, String firmwareVersion) {
        this.runtimeStatus = runtimeStatus;
        this.batteryLevel = batteryLevel;
        this.firmwareVersion = firmwareVersion;
        this.lastOnlineAt = Instant.now();
    }

    // --- Getters and Setters ---

    public Long getTenantId() { return tenantId; }
    public void setTenantId(Long tenantId) { this.tenantId = tenantId; }

    public String getDeviceCode() { return deviceCode; }
    public void setDeviceCode(String deviceCode) { this.deviceCode = deviceCode; }

    public DeviceType getDeviceType() { return deviceType; }
    public void setDeviceType(DeviceType deviceType) { this.deviceType = deviceType; }

    public DeviceStatus getStatus() { return status; }
    public void setStatus(DeviceStatus status) { this.status = status; }

    public String getRuntimeStatus() { return runtimeStatus; }
    public void setRuntimeStatus(String runtimeStatus) { this.runtimeStatus = runtimeStatus; }

    public Integer getBatteryLevel() { return batteryLevel; }
    public void setBatteryLevel(Integer batteryLevel) { this.batteryLevel = batteryLevel; }

    public String getFirmwareVersion() { return firmwareVersion; }
    public void setFirmwareVersion(String firmwareVersion) { this.firmwareVersion = firmwareVersion; }

    public String getDevEui() { return devEui; }
    public void setDevEui(String devEui) { this.devEui = devEui; }

    public Instant getLastOnlineAt() { return lastOnlineAt; }

    /**
     * Reconstitute lastOnlineAt from persistence.
     */
    public void reconstituteLastOnlineAt(Instant lastOnlineAt) { this.lastOnlineAt = lastOnlineAt; }
}
