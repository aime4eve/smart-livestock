package com.ai.openapi.space.dto.internal;

import lombok.Data;

@Data
public class CreateBindingRequest {

    private String nodeId;
    private String resourceId;
    private String resourceType;
}
