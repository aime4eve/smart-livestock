package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionRenewalFailedEvent extends DomainEvent {
    private final Long tenantId;

    public SubscriptionRenewalFailedEvent(Long tenantId) {
        this.tenantId = tenantId;
    }

    public Long getTenantId() { return tenantId; }
}
