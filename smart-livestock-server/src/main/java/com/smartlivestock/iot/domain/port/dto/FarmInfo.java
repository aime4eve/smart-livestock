package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;

public record FarmInfo(Long id, String name, BigDecimal centerLat, BigDecimal centerLng) {
}
