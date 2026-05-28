package com.smartlivestock.iot.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

/**
 * Domain event fired when a device license expires.
 */
public class LicenseExpiredEvent extends DomainEvent {

    private final Long licenseId;
    private final Long deviceId;

    public LicenseExpiredEvent(Long licenseId, Long deviceId) {
        this.licenseId = licenseId;
        this.deviceId = deviceId;
    }

    public Long getLicenseId() { return licenseId; }
    public Long getDeviceId() { return deviceId; }
}
