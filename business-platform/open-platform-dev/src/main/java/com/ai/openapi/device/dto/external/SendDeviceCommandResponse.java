package com.ai.openapi.device.dto.external;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SendDeviceCommandResponse {

    private Integer total_count;
    private Integer success_count;
    private Integer fail_count;
    private List<DeviceCommandSuccessItem> success_list;
    private List<DeviceCommandFailureItem> fail_list;
}
