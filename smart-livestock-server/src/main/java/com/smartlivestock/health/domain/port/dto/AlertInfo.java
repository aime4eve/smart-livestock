package com.smartlivestock.health.domain.port.dto;

public record AlertInfo(Long farmId, Long livestockId, String alertType, String severity, String message) {
}
