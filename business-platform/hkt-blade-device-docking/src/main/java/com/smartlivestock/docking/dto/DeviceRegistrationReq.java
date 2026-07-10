package com.smartlivestock.docking.dto;

import lombok.Data;

@Data
public class DeviceRegistrationReq {
    private LoginUser user;
    private String deviceIdentifier;
    private String deviceTypeCode;
    private String spaceId;
}
