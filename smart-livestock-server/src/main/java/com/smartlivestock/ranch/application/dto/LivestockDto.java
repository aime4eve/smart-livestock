package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.Livestock;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

public record LivestockDto(
        Long id,
        Long farmId,
        String livestockCode,
        String breed,
        String gender,
        LocalDate birthDate,
        BigDecimal weight,
        String healthStatus,
        BigDecimal lastLatitude,
        BigDecimal lastLongitude,
        Instant lastPositionAt
) {
    public static LivestockDto from(Livestock livestock) {
        return new LivestockDto(
                livestock.getId(),
                livestock.getFarmId(),
                livestock.getLivestockCode(),
                livestock.getBreed(),
                livestock.getGender(),
                livestock.getBirthDate(),
                livestock.getWeight(),
                livestock.getHealthStatus().name(),
                livestock.getLastLatitude(),
                livestock.getLastLongitude(),
                livestock.getLastPositionAt()
        );
    }
}
