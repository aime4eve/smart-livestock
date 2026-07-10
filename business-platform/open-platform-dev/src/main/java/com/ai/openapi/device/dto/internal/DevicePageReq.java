package com.ai.openapi.device.dto.internal;

import lombok.Data;

@Data
public class DevicePageReq {

    private String tenantId;
    private String userId;
    private String keyword;
    private String spaceId;
    private Integer current;
    private Integer size;
}
