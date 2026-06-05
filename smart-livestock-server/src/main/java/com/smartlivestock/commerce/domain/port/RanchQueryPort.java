package com.smartlivestock.commerce.domain.port;

public interface RanchQueryPort {
    int countLivestockByFarmIdAndTenantId(Long farmId, Long tenantId);
    int countFencesByFarmIdAndTenantId(Long farmId, Long tenantId);
}
