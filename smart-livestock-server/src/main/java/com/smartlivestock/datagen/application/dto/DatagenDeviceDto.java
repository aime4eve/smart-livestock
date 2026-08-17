package com.smartlivestock.datagen.application.dto;

import java.time.Instant;

public record DatagenDeviceDto(
        Long deviceId, String deviceCode, String devEui, String deviceType,
        Long livestockId, String livestockCode, String runtimeStatus,
        boolean selected, boolean eligible, String ineligibleReason,
        Instant lastGeneratedAt) {}
