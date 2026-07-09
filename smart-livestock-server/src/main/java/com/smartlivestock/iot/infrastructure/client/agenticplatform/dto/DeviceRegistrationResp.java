package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceRegistrationResp {
    private String deviceId;
    private String deviceIdentifier;
    private String deviceTypeId;
    private String status;
    private String createTime;
}
