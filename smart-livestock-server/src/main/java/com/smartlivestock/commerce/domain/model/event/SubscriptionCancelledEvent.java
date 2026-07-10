package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionCancelledEvent extends DomainEvent {
    private final Long tenantId;

    public SubscriptionCancelledEvent(Long tenantId) {
        this.tenantId = tenantId;
    }

    public Long getTenantId() { return tenantId; }
}
