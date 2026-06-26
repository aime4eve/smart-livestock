package com.smartlivestock.datagen.domain.port.dto;

import java.math.BigDecimal;
import java.time.Instant;

public record AnomalyScoreInfo(
        Long livestockId, BigDecimal anomalyScore, String anomalyType, Instant createdAt) {}
