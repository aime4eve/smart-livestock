package com.smartlivestock.iot.application.dto;

import com.smartlivestock.iot.domain.model.Installation;

import java.time.Instant;

public record InstallationDto(
        Long id,
        Long deviceId,
        Long livestockId,
        Long operatorId,
        Instant installedAt,
        Instant removedAt,
        boolean active
) {
    public static InstallationDto from(Installation installation) {
        return new InstallationDto(
                installation.getId(),
                installation.getDeviceId(),
                installation.getLivestockId(),
                installation.getOperatorId(),
                installation.getInstalledAt(),
                installation.getRemovedAt(),
                installation.isActive()
        );
    }
}
