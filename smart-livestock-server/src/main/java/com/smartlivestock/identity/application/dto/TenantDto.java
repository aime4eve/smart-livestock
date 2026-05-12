package com.smartlivestock.identity.application.dto;

import com.smartlivestock.identity.domain.model.Tenant;

public record TenantDto(
        Long id,
        String name,
        String contactName,
        String contactPhone,
        String phase
) {
    public static TenantDto from(Tenant tenant) {
        return new TenantDto(
                tenant.getId(),
                tenant.getName(),
                tenant.getContactName(),
                tenant.getContactPhone(),
                tenant.getPhase().name()
        );
    }
}
