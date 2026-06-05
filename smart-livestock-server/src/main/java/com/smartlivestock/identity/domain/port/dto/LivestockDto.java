package com.smartlivestock.identity.domain.port.dto;

public record LivestockDto(Long id, Long farmId, String livestockCode, String breed, String gender, String status) {
}
