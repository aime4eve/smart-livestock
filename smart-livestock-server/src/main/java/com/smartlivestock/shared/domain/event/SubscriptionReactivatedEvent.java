package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionReactivatedEvent extends DomainEvent {
    private final Long tenantId;

    public SubscriptionReactivatedEvent(Long tenantId) {
        this.tenantId = tenantId;
    }

    public Long getTenantId() { return tenantId; }
}
