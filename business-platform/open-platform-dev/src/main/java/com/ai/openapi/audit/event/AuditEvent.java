package com.ai.openapi.audit.event;

import lombok.Data;

@Data
public class AuditEvent {

    private Long appId;
    private Long keyId;
    private String httpMethod;
    private String requestPath;
    private short responseStatus;
    private String clientIp;
    private int requestDuration;
}
