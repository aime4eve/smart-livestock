package com.ai.openapi.device.dto.internal;

import com.ai.openapi.common.dto.LoginUser;
import lombok.Data;

import java.util.List;

@Data
public class DeviceRemoveReq {

    private LoginUser user;
    private List<String> deviceIds;
}
