package com.smartlivestock.iot.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

/**
 * Domain event fired when a device is activated.
 */
public class DeviceActivatedEvent extends DomainEvent {

    private final Long deviceId;
    private final String deviceCode;

    public DeviceActivatedEvent(Long deviceId, String deviceCode) {
        this.deviceId = deviceId;
        this.deviceCode = deviceCode;
    }

    public Long getDeviceId() { return deviceId; }
    public String getDeviceCode() { return deviceCode; }
}
