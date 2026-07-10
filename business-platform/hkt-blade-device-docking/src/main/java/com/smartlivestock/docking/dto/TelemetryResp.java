package com.smartlivestock.docking.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.Map;

/**
 * Telemetry data item from blade /telemetry/history/latest and /query.
 * Verified response: deviceId, telemetryJson (map of property -> value), ts.
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TelemetryResp {
    private String deviceId;
    private Map<String, Object> telemetryJson;
    private String ts;
}
