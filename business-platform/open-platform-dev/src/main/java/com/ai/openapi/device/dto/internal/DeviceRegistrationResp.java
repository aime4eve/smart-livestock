package com.ai.openapi.device.dto.internal;

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
