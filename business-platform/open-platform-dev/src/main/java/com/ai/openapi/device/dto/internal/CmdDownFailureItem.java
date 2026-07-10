package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class CmdDownFailureItem {

    private String deviceId;
    private Boolean enqueue;
    private Boolean waitForResponse;
    /** 上游可能为功能描述或序列化后的指令内容字符串 */
    private String func;
    private String errorMsg;
}
