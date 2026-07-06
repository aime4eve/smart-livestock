package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DeviceCommandSuccessItem {

    private String record_id;
    /** WAITING, ISSUING, SUCCESS, FAIL, TIMEOUT, RETRY, EXPIRE 等 */
    private String command_status;
    private String error_message;
}
