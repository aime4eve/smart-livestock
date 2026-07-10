package com.smartlivestock.ranch.application.dto;

import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.dto.DeviceBrief;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

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
        Instant lastPositionAt,
        BigDecimal bodyTemp,
        String activityLevel,
        String ruminationFreq,
        List<DeviceBrief> devices
) {
    public LivestockDto {
        if (devices == null) {
            devices = List.of();
        }
    }

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
                livestock.getLastPositionAt(),
                null, null, null,
                List.of()
        );
    }

    /**
     * Build detail DTO enriched with latest health-snapshot data.
     */
    public static LivestockDto detail(Livestock livestock, HealthQueryPort.LivestockHealthState health) {
        BigDecimal bodyTemp = null;
        String activityLevel = null;
        String ruminationFreq = null;

        if (health != null) {
            if (health.currentTemp() != null) {
                bodyTemp = health.currentTemp().setScale(2, RoundingMode.HALF_UP);
            }
            if (health.currentMotility() != null) {
                ruminationFreq = health.currentMotility().setScale(1, RoundingMode.HALF_UP).toPlainString();
            }
            if (health.activityStatus() != null) {
                activityLevel = health.activityStatus();
            }
        }

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
                livestock.getLastPositionAt(),
                bodyTemp, activityLevel, ruminationFreq,
                List.of()
        );
    }

    /**
     * Create a copy of the given DTO with devices populated.
     */
    public LivestockDto withDevices(List<DeviceBrief> devices) {
        return new LivestockDto(
                id, farmId, livestockCode, breed, gender, birthDate, weight,
                healthStatus, lastLatitude, lastLongitude, lastPositionAt,
                bodyTemp, activityLevel, ruminationFreq,
                devices != null ? devices : List.of()
        );
    }
}
