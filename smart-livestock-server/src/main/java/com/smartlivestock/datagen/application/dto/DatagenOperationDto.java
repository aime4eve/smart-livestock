package com.smartlivestock.datagen.application.dto;

import java.time.Instant;

public record DatagenOperationDto(
        Long id, String action, Long operatorId, String operatorRole,
        Instant occurredAt, String summary) {}
