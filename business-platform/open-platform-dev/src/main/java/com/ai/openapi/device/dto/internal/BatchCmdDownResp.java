package com.ai.openapi.device.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Data;

import java.util.List;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonIgnoreProperties(ignoreUnknown = true)
public class BatchCmdDownResp {

    private Integer totalCount;
    private Integer successCount;
    private Integer failCount;
    private List<CmdDownResp> successList;
    private List<CmdDownFailureItem> failList;
}
