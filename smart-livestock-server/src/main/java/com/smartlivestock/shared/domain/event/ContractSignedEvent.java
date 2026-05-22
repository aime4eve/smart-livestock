package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class ContractSignedEvent extends DomainEvent {
    private final Long tenantId;
    private final String contractNumber;

    public ContractSignedEvent(Long tenantId, String contractNumber) {
        this.tenantId = tenantId;
        this.contractNumber = contractNumber;
    }

    public Long getTenantId() { return tenantId; }
    public String getContractNumber() { return contractNumber; }
}
