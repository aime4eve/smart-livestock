package com.ai.openapi.device.dto.internal;

import lombok.Data;

@Data
public class DeviceListReq {

    private String tenantId;
    private String userId;
    private String keyword;
}
