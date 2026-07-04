package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RegisterDeviceResponse {

    private String device_id;
    private String type;
    private String type_name;
    private String name;
    private String status;
    private String created_at;
}
