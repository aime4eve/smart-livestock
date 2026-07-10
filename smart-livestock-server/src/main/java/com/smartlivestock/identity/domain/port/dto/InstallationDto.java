package com.smartlivestock.identity.domain.port.dto;

public record InstallationDto(Long id, Long deviceId, Long livestockId, String deviceType, String deviceStatus) {
}
