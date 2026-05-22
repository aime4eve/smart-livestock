package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class ContractSuspendedEvent extends DomainEvent {
    private final Long tenantId;
    private final String contractNumber;

    public ContractSuspendedEvent(Long tenantId, String contractNumber) {
        this.tenantId = tenantId;
        this.contractNumber = contractNumber;
    }

    public Long getTenantId() { return tenantId; }
    public String getContractNumber() { return contractNumber; }
}
