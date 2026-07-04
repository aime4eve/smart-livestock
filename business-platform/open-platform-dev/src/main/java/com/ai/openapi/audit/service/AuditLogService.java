package com.ai.openapi.audit.service;

import com.ai.openapi.audit.event.AuditEvent;
import com.ai.openapi.entity.OpenApiAuditLog;
import com.ai.openapi.mapper.OpenApiAuditLogMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class AuditLogService {

    private final OpenApiAuditLogMapper auditLogMapper;

    public AuditLogService(OpenApiAuditLogMapper auditLogMapper) {
        this.auditLogMapper = auditLogMapper;
    }

    @Async
    public void recordAsync(AuditEvent event) {
        try {
            OpenApiAuditLog entity = new OpenApiAuditLog();
            entity.setAppId(event.getAppId());
            entity.setKeyId(event.getKeyId());
            entity.setHttpMethod(event.getHttpMethod());
            entity.setRequestPath(event.getRequestPath());
            entity.setResponseStatus(event.getResponseStatus());
            entity.setClientIp(event.getClientIp());
            entity.setRequestDuration(event.getRequestDuration());
            auditLogMapper.insert(entity);
        } catch (Exception e) {
            log.error("写入审计日志失败: {}", e.getMessage());
        }
    }
}
