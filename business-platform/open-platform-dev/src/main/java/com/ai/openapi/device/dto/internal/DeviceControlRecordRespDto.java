package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

/**
 * 设备中台控制记录（queryControlRecordByIds 返回元素）。
 */
@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeviceControlRecordRespDto {

    private String id;
    private String deviceId;
    private String triggerSource;
    private String triggerSourceText;
    private String funcName;
    private String funcParams;
    private Integer cmdState;
    private String cmdStateText;
    private String errorMsg;
    private String createTime;
    private String operatorName;
}
