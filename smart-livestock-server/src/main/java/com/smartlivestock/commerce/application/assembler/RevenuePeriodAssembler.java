package com.smartlivestock.commerce.application.assembler;

import com.smartlivestock.commerce.application.dto.RevenuePeriodResponse;
import com.smartlivestock.commerce.domain.model.RevenuePeriod;

import java.util.List;

/**
 * Maps RevenuePeriod domain objects to RevenuePeriodResponse DTOs.
 */
public final class RevenuePeriodAssembler {

    private RevenuePeriodAssembler() {}

    public static RevenuePeriodResponse toResponse(RevenuePeriod domain) {
        RevenuePeriodResponse dto = new RevenuePeriodResponse();
        dto.setId(domain.getId());
        dto.setContractId(domain.getContractId());
        dto.setTenantId(domain.getTenantId());
        dto.setPeriodStart(domain.getPeriodStart());
        dto.setPeriodEnd(domain.getPeriodEnd());
        dto.setGrossAmount(domain.getGrossAmount());
        dto.setPlatformShare(domain.getPlatformShare());
        dto.setPartnerShare(domain.getPartnerShare());
        dto.setRevenueShareRatio(domain.getRevenueShareRatio());
        dto.setStatus(domain.getStatus() != null ? domain.getStatus().name() : null);
        dto.setSettledAt(domain.getSettledAt());
        return dto;
    }

    public static List<RevenuePeriodResponse> toResponseList(List<RevenuePeriod> domains) {
        return domains.stream().map(RevenuePeriodAssembler::toResponse).toList();
    }
}
