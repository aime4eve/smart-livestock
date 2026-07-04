package com.ai.openapi.device.dto.internal;

import com.ai.openapi.common.dto.LoginUser;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class BusinessCmdDownReq {

    private LoginUser user;
    private String requestId;
    private String deviceId;
    private List<String> subDeviceIds;
    private String triggerSource;
    private DeviceControlFunctionDto func;
    private CmdDownConfigDto downConfig;
}
