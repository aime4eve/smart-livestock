package com.smartlivestock.identity.domain.repository;

import com.smartlivestock.identity.domain.model.AuditLog;

import java.util.List;

public interface AuditLogRepository {
    AuditLog save(AuditLog auditLog);
    List<AuditLog> findAll(int page, int pageSize, Long tenantId, Long userId,
                           String action, String startTime, String endTime);
    long count(Long tenantId, Long userId, String action, String startTime, String endTime);
}
