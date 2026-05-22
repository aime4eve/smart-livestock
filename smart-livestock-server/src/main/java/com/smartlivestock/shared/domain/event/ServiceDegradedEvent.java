package com.smartlivestock.shared.domain.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class ServiceDegradedEvent extends DomainEvent {
    private final Long tenantId;
    private final String serviceName;

    public ServiceDegradedEvent(Long tenantId, String serviceName) {
        this.tenantId = tenantId;
        this.serviceName = serviceName;
    }

    public Long getTenantId() { return tenantId; }
    public String getServiceName() { return serviceName; }
}
