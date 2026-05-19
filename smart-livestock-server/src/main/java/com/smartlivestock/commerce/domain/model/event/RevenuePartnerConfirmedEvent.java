package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class RevenuePartnerConfirmedEvent extends DomainEvent {
    private final Long periodId;
    private final Long contractId;

    public RevenuePartnerConfirmedEvent(Long periodId, Long contractId) {
        this.periodId = periodId;
        this.contractId = contractId;
    }

    public Long getPeriodId() { return periodId; }
    public Long getContractId() { return contractId; }
}
