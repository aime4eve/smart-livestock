package com.smartlivestock.identity.infrastructure.persistence.mapper;

import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.infrastructure.persistence.entity.AuditLogJpaEntity;

public final class AuditLogMapper {

    private AuditLogMapper() {}

    public static AuditLogJpaEntity toJpaEntity(AuditLog domain) {
        AuditLogJpaEntity entity = new AuditLogJpaEntity();
        entity.setId(domain.getId());
        entity.setEventId(domain.getEventId());
        entity.setEventType(domain.getEventType());
        entity.setTenantId(domain.getTenantId());
        entity.setUserId(domain.getUserId());
        entity.setAction(domain.getAction());
        entity.setDetails(domain.getDetails());
        entity.setOccurredAt(domain.getOccurredAt());
        return entity;
    }

    public static AuditLog toDomain(AuditLogJpaEntity entity) {
        AuditLog domain = new AuditLog(
                entity.getEventId(),
                entity.getEventType(),
                entity.getTenantId(),
                entity.getUserId(),
                entity.getAction(),
                entity.getDetails(),
                entity.getOccurredAt()
        );
        domain.setId(entity.getId());
        domain.setCreatedAt(entity.getCreatedAt());
        return domain;
    }
}
