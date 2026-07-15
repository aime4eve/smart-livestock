package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DevicePageReq {
    private Integer current = 1;
    private Integer size = 20;
    private String deviceTypeCode;
    private String deviceName;
    private String keyword;
}
