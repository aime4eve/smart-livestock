package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.Map;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TelemetryResp {
    private String deviceId;
    private Map<String, Object> telemetryJson;
    private String ts;
}
