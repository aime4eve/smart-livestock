package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;

public record CoordinateInfo(BigDecimal latitude, BigDecimal longitude) {
}
