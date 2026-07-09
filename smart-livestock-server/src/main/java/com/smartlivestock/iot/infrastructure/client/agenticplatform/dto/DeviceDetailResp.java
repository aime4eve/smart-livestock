package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

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
