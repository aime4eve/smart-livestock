package com.smartlivestock.datagen.application.dto;

public record DatagenClearResultDto(
        long telemetryRows,
        long gpsRows,
        long temperatureRows,
        long motilityRows,
        long activityRows,
        long estrusRows,
        long anomalyRows,
        long alertRows,
        long unattributableHealthRows,
        long unattributableAlertRows,
        String limitationKey) {}
