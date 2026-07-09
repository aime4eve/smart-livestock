package com.smartlivestock.iot.infrastructure.client.agenticplatform.dto;

import lombok.Data;

@Data
public class DeviceRegistrationReq {
    private LoginUser user;
    private String deviceIdentifier;
    private String deviceTypeCode;
    private String spaceId;
}
