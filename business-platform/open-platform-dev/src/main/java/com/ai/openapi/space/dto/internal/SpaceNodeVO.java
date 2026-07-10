package com.ai.openapi.space.dto.internal;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class SpaceNodeVO {

    private String nodeId;
    private String parentId;
    private String name;
    private BigDecimal area;
    private String rootId;
    private String levelId;
    private String levelName;
    private String path;
    private List<SpaceNodeVO> children;
    private String createdBy;
    private String createdAt;
}
