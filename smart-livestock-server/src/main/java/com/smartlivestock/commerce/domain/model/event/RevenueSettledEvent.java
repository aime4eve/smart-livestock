package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class RevenueSettledEvent extends DomainEvent {
    private final Long contractId;
    private final Long tenantId;

    public RevenueSettledEvent(Long contractId, Long tenantId) {
        this.contractId = contractId;
        this.tenantId = tenantId;
    }

    public Long getContractId() { return contractId; }
    public Long getTenantId() { return tenantId; }
}
