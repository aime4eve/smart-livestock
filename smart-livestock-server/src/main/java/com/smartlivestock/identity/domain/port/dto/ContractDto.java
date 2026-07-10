package com.smartlivestock.identity.domain.port.dto;

import java.math.BigDecimal;
import java.time.Instant;

public record ContractDto(Long id, Long tenantId, String partnerName, BigDecimal revenueSharePercent, Instant startDate, Instant endDate, String status) {
}
