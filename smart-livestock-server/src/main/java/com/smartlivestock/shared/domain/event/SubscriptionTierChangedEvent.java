package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionTierChangedEvent extends DomainEvent {
    private final Long tenantId;
    private final String oldTier;
    private final String newTier;

    public SubscriptionTierChangedEvent(Long tenantId, String oldTier, String newTier) {
        this.tenantId = tenantId;
        this.oldTier = oldTier;
        this.newTier = newTier;
    }

    public Long getTenantId() { return tenantId; }
    public String getOldTier() { return oldTier; }
    public String getNewTier() { return newTier; }
}
