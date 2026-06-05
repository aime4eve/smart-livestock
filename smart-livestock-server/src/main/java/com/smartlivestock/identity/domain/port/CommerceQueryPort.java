package com.smartlivestock.identity.domain.port;

import com.smartlivestock.identity.domain.port.dto.ContractDto;

import java.util.List;
import java.util.Optional;

public interface CommerceQueryPort {
    Optional<ContractDto> findActiveContractByTenantId(Long tenantId);
}
