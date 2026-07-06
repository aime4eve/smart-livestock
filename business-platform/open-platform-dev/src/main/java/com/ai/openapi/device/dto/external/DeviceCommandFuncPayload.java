package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.Map;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceCommandFuncPayload {

    @NotBlank(message = "method 不能为空")
    @Size(max = 100, message = "method 长度不能超过 100")
    private String method;

    private Map<String, Object> params;
}
