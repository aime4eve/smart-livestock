package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionCreatedEvent extends DomainEvent {
    private final Long tenantId;
    private final String tier;

    public SubscriptionCreatedEvent(Long tenantId, String tier) {
        this.tenantId = tenantId;
        this.tier = tier;
    }

    public Long getTenantId() { return tenantId; }
    public String getTier() { return tier; }
}
