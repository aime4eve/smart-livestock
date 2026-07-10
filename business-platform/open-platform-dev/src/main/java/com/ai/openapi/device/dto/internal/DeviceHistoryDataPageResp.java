package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceHistoryDataPageResp {

    private Long total;
    private Long current;
    private Long size;
    private List<Map<String, Object>> records;
}
