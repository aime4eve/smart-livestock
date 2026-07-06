package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceCommandFailureItem {

    private String device_id;
    private Boolean enqueue;
    private Boolean wait_for_response;
    private String func;
    private String error_message;
}
