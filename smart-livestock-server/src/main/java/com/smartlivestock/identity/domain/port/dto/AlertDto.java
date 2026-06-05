package com.smartlivestock.identity.domain.port.dto;

public record AlertDto(Long id, Long farmId, Long livestockId, String type, String severity, String status, String message) {
}
