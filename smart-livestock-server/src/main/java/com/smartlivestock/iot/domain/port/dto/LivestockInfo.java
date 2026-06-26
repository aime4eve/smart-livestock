package com.smartlivestock.iot.domain.port.dto;

/**
 * DTO for livestock data needed by IoT context.
 * Only includes fields that IoT actually uses.
 */
public record LivestockInfo(Long id, Long farmId, String livestockCode, String gender,
                            java.math.BigDecimal lastLatitude, java.math.BigDecimal lastLongitude) {
}
