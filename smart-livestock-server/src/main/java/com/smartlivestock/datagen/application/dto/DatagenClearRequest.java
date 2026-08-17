package com.smartlivestock.datagen.application.dto;

import java.time.Instant;

public record DatagenClearRequest(
        Long farmId, String rangeType, Instant from, Instant to,
        String confirmText) {
    public DatagenClearRequest(Long farmId, String rangeType, Instant from, Instant to) {
        this(farmId, rangeType, from, to, null);
    }
}
