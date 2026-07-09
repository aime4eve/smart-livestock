package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import java.util.List;

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
