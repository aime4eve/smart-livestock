package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceHistoryDataPageReq {

    private String startTime;
    private String endTime;
    private String aggregation;
    private Integer current;
    private Integer size;
}
