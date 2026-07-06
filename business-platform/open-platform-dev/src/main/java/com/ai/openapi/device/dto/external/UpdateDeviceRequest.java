package com.ai.openapi.device.dto.external;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateDeviceRequest {

    @Size(max = 100, message = "name 长度不能超过 100")
    private String name;
}
