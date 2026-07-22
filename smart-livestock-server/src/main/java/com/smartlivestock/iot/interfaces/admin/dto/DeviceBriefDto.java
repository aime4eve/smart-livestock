package com.smartlivestock.iot.interfaces.admin.dto;

public class DeviceBriefDto {
    private final Long id;
    private final String deviceCode;
    private final boolean platformBound;

    public DeviceBriefDto(Long id, String deviceCode) {
        this.id = id;
        this.deviceCode = deviceCode;
        this.platformBound = false;
    }

    public DeviceBriefDto(Long id, String deviceCode, boolean platformBound) {
        this.id = id;
        this.deviceCode = deviceCode;
        this.platformBound = platformBound;
    }

    public Long getId() { return id; }
    public String getDeviceCode() { return deviceCode; }
    public boolean isPlatformBound() { return platformBound; }
}
