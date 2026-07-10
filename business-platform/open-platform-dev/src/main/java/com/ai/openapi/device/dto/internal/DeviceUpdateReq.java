package com.ai.openapi.device.dto.internal;

import com.ai.openapi.common.dto.LoginUser;
import lombok.Data;

@Data
public class DeviceUpdateReq {

    private LoginUser user;
    private String deviceId;
    private String deviceName;
}
