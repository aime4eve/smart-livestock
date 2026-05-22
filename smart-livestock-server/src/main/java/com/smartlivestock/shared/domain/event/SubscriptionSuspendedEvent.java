package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionSuspendedEvent extends DomainEvent {
    private final Long tenantId;

    public SubscriptionSuspendedEvent(Long tenantId) {
        this.tenantId = tenantId;
    }

    public Long getTenantId() { return tenantId; }
}
