package com.ai.openapi.device.dto.internal;

import com.ai.openapi.common.dto.LoginUser;
import lombok.Data;

@Data
public class DeviceRegistrationReq {

    private LoginUser user;
    private String deviceIdentifier;
    private String deviceTypeCode;
    private String spaceId;
}
