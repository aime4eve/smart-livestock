package com.smartlivestock.iot.interfaces.admin.dto;

public class DeviceBriefDto {
    private final Long id;
    private final String deviceCode;

    public DeviceBriefDto(Long id, String deviceCode) {
        this.id = id;
        this.deviceCode = deviceCode;
    }

    public Long getId() { return id; }
    public String getDeviceCode() { return deviceCode; }
}
