package com.smartlivestock.docking.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

/**
 * Blade device detail response (from /feign/v1/device/lifecycle/getDeviceDetail).
 * Verified against real blade: deviceId, deviceName, deviceIdentifier, deviceTypeId,
 * deviceTypeCode, onlineStatus, rssi, snr, lastActiveTime, etc.
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceDetailResp {
    private String deviceId;
    private String deviceName;
    private String deviceIdentifier;
    private String deviceTypeId;
    private String deviceTypeCode;
    private String tenantId;
    private Integer onlineStatus;
    private String onlineStatusName;
    private String lastActiveTime;
    private Integer rssi;
    private String snr;
    private String lastGateway;
    private String createTime;
}
