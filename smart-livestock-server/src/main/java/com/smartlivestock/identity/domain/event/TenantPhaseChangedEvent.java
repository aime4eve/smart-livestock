package com.smartlivestock.identity.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;
import com.smartlivestock.identity.domain.model.TenantPhase;

public class TenantPhaseChangedEvent extends DomainEvent {

    private final Long tenantId;
    private final TenantPhase newPhase;

    public TenantPhaseChangedEvent(Long tenantId, TenantPhase newPhase) {
        this.tenantId = tenantId;
        this.newPhase = newPhase;
    }

    public Long getTenantId() { return tenantId; }
    public TenantPhase getNewPhase() { return newPhase; }
}
