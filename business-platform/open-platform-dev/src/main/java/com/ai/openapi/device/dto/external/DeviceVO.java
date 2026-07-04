package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceVO {

    private String device_id;
    private String name;
    private String type;
    private String type_name;
    private String status;
    private Integer status_code;
    private String created_at;
    private String last_active_at;
}
