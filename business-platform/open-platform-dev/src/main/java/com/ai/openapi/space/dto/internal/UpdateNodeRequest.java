package com.ai.openapi.space.dto.internal;

import com.ai.openapi.common.dto.LoginUser;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateNodeRequest {

    private LoginUser user;
    private String tenantId;
    private String nodeId;
    private String name;
    private BigDecimal area;
    private String parentId;
    private String rootId;
    private String levelId;
    private String path;
}
