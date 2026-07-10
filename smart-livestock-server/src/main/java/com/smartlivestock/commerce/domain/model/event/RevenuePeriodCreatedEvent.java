package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class RevenuePeriodCreatedEvent extends DomainEvent {
    private final Long contractId;
    private final Long tenantId;

    public RevenuePeriodCreatedEvent(Long contractId, Long tenantId) {
        this.contractId = contractId;
        this.tenantId = tenantId;
    }

    public Long getContractId() { return contractId; }
    public Long getTenantId() { return tenantId; }
}
