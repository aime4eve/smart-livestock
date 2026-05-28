package com.smartlivestock.commerce.domain.model.event;

import com.smartlivestock.shared.domain.DomainEvent;

public class ServiceProvisionedEvent extends DomainEvent {
    private final Long tenantId;
    private final String serviceName;

    public ServiceProvisionedEvent(Long tenantId, String serviceName) {
        this.tenantId = tenantId;
        this.serviceName = serviceName;
    }

    public Long getTenantId() { return tenantId; }
    public String getServiceName() { return serviceName; }
}
