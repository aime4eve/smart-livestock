package com.smartlivestock.datagen.application.dto;

public record DatagenFarmDto(
        Long farmId, String farmName, Long tenantId, String tenantName,
        boolean enabled, int selectedDeviceCount) {}
