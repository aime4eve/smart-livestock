package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;

public record FarmInfo(Long id, BigDecimal centerLat, BigDecimal centerLng) {
}
