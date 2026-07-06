package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

/**
 * 开放平台：查询命令状态响应（snake_case）。
 */
@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceCommandStatusVO {

    private String record_id;
    private String device_id;
    private String trigger_source;
    private String trigger_source_text;
    private String func_name;
    private String func_params;
    private Integer cmd_state;
    private String cmd_state_text;
    private String error_msg;
    private String create_time;
    private String operator_name;
}
