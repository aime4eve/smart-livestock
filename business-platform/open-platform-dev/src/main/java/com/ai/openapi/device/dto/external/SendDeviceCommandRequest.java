package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SendDeviceCommandRequest {

    private List<String> subDeviceIds;

    @NotNull(message = "func 不能为空")
    @Valid
    private DeviceCommandFuncPayload func;
}
