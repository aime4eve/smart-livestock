package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class RevenueSettledEvent extends DomainEvent {
    private final Long periodId;
    private final Long contractId;

    public RevenueSettledEvent(Long periodId, Long contractId) {
        this.periodId = periodId;
        this.contractId = contractId;
    }

    public Long getPeriodId() { return periodId; }
    public Long getContractId() { return contractId; }
}
