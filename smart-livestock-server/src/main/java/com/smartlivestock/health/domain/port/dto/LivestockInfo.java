package com.smartlivestock.health.domain.port.dto;

public record LivestockInfo(Long id, Long farmId, String livestockCode, String gender, String breed) {
}
