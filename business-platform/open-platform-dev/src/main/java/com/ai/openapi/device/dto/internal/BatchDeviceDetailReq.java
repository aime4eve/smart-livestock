package com.ai.openapi.device.dto.internal;

import lombok.Data;

import java.util.List;

@Data
public class BatchDeviceDetailReq {

    private List<String> deviceIds;
}
