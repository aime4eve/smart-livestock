package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class ServiceQuotaAdjustedEvent extends DomainEvent {
    private final Long tenantId;
    private final String serviceName;
    private final int newQuota;

    public ServiceQuotaAdjustedEvent(Long tenantId, String serviceName, int newQuota) {
        this.tenantId = tenantId;
        this.serviceName = serviceName;
        this.newQuota = newQuota;
    }

    public Long getTenantId() { return tenantId; }
    public String getServiceName() { return serviceName; }
    public int getNewQuota() { return newQuota; }
}
