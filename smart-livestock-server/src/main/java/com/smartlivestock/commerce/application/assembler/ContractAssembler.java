package com.smartlivestock.commerce.application.assembler;

import com.smartlivestock.commerce.application.dto.ContractResponse;
import com.smartlivestock.commerce.domain.model.Contract;

import java.util.List;

/**
 * Maps Contract domain objects to ContractResponse DTOs.
 */
public final class ContractAssembler {

    private ContractAssembler() {}

    public static ContractResponse toResponse(Contract domain) {
        ContractResponse dto = new ContractResponse();
        dto.setId(domain.getId());
        dto.setTenantId(domain.getTenantId());
        dto.setContractNumber(domain.getContractNumber());
        dto.setBillingModel(domain.getBillingModel());
        dto.setEffectiveTier(domain.getEffectiveTier());
        dto.setRevenueShareRatio(domain.getRevenueShareRatio());
        dto.setStatus(domain.getStatus() != null ? domain.getStatus().name() : null);
        dto.setSignedBy(domain.getSignedBy());
        dto.setSignedAt(domain.getSignedAt());
        dto.setStartedAt(domain.getStartedAt());
        dto.setExpiresAt(domain.getExpiresAt());
        return dto;
    }

    public static List<ContractResponse> toResponseList(List<Contract> domains) {
        return domains.stream().map(ContractAssembler::toResponse).toList();
    }
}
