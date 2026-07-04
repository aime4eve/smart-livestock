package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.Map;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceControlFunctionDto {

    private String method;
    private Map<String, Object> params;
}
