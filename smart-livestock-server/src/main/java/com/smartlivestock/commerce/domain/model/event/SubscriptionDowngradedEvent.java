package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class SubscriptionDowngradedEvent extends DomainEvent {
    private final Long tenantId;
    private final String fromTier;
    private final String toTier;

    public SubscriptionDowngradedEvent(Long tenantId, String fromTier, String toTier) {
        this.tenantId = tenantId;
        this.fromTier = fromTier;
        this.toTier = toTier;
    }

    public Long getTenantId() { return tenantId; }
    public String getFromTier() { return fromTier; }
    public String getToTier() { return toTier; }
}
