package com.smartlivestock.iot.domain.port.dto;

import java.math.BigDecimal;
import java.util.List;

public record FenceInfo(Long id, String name, List<CoordinateInfo> coordinates) {
}
