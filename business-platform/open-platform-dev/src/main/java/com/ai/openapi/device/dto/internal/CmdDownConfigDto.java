package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CmdDownConfigDto {

    private Integer responseTimeout;
    private Integer retryTimes;
    private Integer retryInterval;
    private Boolean tryAgainImmediately;
}
