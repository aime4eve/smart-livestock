package com.smartlivestock.datagen.domain.port.dto;

import java.time.Instant;

public record AlertInfo(
        Long alertId, Long livestockId, String type, String status,
        Instant createdAt
) {}
