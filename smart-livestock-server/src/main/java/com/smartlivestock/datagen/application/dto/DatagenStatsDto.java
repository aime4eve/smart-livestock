package com.smartlivestock.datagen.application.dto;

import java.time.Instant;

public record DatagenStatsDto(
        String statsTimeZone,
        int selectedTotal,
        int selectedTrackerCount,
        int selectedCapsuleCount,
        long todayTelemetryRows,
        long todayGpsRows,
        long todayHealthRows,
        Instant lastGeneratedAt) {}
