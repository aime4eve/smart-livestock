package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceTelemetryVO {

    private String device_id;
    private String name;
    private String identifier;
    private String type_id;
    private String type_name;
    private String type;
    private String online_status_name;
    private Integer online_status;
    private String last_active_at;
    private Boolean control_enabled;
    private Boolean data_collection_enabled;
    private Integer rssi;
    private BigDecimal snr;
    private Integer spreading_factor;
    private String last_gateway;
    private List<TelemetryPropertyVO> telemetry_properties;
    private List<SubDeviceTelemetryVO> sub_devices;

    @Data
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public static class TelemetryPropertyVO {
        private String identifier;
        private String name;
        private String data_type;
        private Object specs;
        private String description;
        private Object value;
    }

    @Data
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public static class SubDeviceTelemetryVO {
        private String sub_device_id;
        private String sub_device_name;
        private String sub_device_identifier;
        private String device_type_id;
        private String last_active_at;
        private List<TelemetryPropertyVO> telemetry_properties;
    }
}
