package com.smartlivestock.docking.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.List;

/**
 * Request for blade telemetry queries (/latest and /query).
 * Verified params: deviceIds (array), deviceTypeCode, startTime, endTime, current, size.
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TelemetryQueryReq {
    private List<String> deviceIds;
    private String deviceTypeCode;
    private String startTime;
    private String endTime;
    private Integer current = 1;
    private Integer size = 100;
}
