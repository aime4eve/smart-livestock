package com.smartlivestock.ranch.domain.port.dto;

import java.math.BigDecimal;

public record FarmInfo(Long id, Long tenantId, String name, BigDecimal latitude, BigDecimal longitude) {
}
