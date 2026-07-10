package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.math.BigDecimal;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceDetailResp {

    private String deviceId;
    private String deviceName;
    private String deviceIdentifier;
    private String deviceTypeId;
    private String deviceTypeName;
    private String deviceTypeCode;
    private String tenantId;
    private Integer onlineStatus;
    private String onlineStatusName;
    private String lastActiveTime;
    private Integer controlEnabled;
    private Integer dataCollectionEnabled;
    private Integer offlineDuration;
    private String createTime;
    private Integer rssi;
    private BigDecimal snr;
    private Integer sf;
    private String lastGateway;
}
