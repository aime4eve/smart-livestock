package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceTelemetryResp {

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
    private Integer isControlEnabled;
    private Integer isDataCollectionEnabled;
    private Integer offlineDuration;
    private String createTime;
    private Integer rssi;
    private BigDecimal snr;
    private Integer sf;
    private String lastGateway;
    private List<TelemetryPropertyDto> telemetryProperties;
    private List<SubDeviceTelemetryResp> subDevices;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TelemetryPropertyDto {
        private String identifier;
        private String name;
        private String dataType;
        private Object specs;
        private String description;
        private Object value;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class SubDeviceTelemetryResp {
        private String subDeviceId;
        private String deviceId;
        private String subDeviceName;
        private String subDeviceIdentifier;
        private String deviceTypeId;
        private String lastActiveTime;
        private List<TelemetryPropertyDto> telemetryProperties;
    }
}
