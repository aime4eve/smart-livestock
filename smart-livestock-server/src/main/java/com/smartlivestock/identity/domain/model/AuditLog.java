package com.smartlivestock.identity.domain.model;

import java.time.Instant;
import java.util.Map;

public class AuditLog {
    private Long id;
    private final String eventId;
    private final String eventType;
    private final Long tenantId;
    private final Long userId;
    private final String action;
    private final Map<String, Object> details;
    private final Instant occurredAt;
    private Instant createdAt;

    public AuditLog(String eventId, String eventType, Long tenantId, Long userId,
                    String action, Map<String, Object> details, Instant occurredAt) {
        this.eventId = eventId;
        this.eventType = eventType;
        this.tenantId = tenantId;
        this.userId = userId;
        this.action = action;
        this.details = details;
        this.occurredAt = occurredAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getEventId() { return eventId; }
    public String getEventType() { return eventType; }
    public Long getTenantId() { return tenantId; }
    public Long getUserId() { return userId; }
    public String getAction() { return action; }
    public Map<String, Object> getDetails() { return details; }
    public Instant getOccurredAt() { return occurredAt; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
