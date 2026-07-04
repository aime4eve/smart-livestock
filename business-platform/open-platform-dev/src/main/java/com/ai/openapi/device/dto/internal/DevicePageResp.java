package com.ai.openapi.device.dto.internal;

import lombok.Data;

import java.util.List;

@Data
public class DevicePageResp {

    private Long total;
    private Integer current;
    private Integer pageSize;
    private List<DeviceDetailResp> records;
}
