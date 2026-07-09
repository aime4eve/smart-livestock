package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.List;
import java.util.Map;

/**
 * Device detail + telemetry response (from /feign/v1/device/lifecycle/getDeviceDetailWithTelemetry).
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceTelemetryResp {
    private String deviceId;
    private String deviceName;
    private String deviceIdentifier;
    private String deviceTypeId;
    private String deviceTypeCode;
    private Integer onlineStatus;
    private String onlineStatusName;
    private String lastActiveTime;
    private Integer rssi;
    private String snr;
    private String lastGateway;
    private String createTime;
    private List<TelemetryProperty> telemetryProperties;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TelemetryProperty {
        private String identifier;
        private String name;
        private String dataType;
        private Map<String, Object> specs;
        private String description;
        private Object value;
    }
}
