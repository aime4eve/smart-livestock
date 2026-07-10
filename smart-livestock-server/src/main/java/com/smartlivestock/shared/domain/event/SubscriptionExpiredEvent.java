package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionExpiredEvent extends DomainEvent {
    private final Long tenantId;

    public SubscriptionExpiredEvent(Long tenantId) {
        this.tenantId = tenantId;
    }

    public Long getTenantId() { return tenantId; }
}
