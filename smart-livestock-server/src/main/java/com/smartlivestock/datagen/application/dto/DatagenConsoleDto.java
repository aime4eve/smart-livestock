package com.smartlivestock.datagen.application.dto;

import java.util.List;

public record DatagenConsoleDto(
        DatagenFarmDto farm,
        boolean enabled,
        DatagenScenarioDto scenario,
        DatagenRulesDto rules,
        List<DatagenDeviceDto> devices,
        DatagenStatsDto stats,
        List<DatagenOperationDto> operations) {}
