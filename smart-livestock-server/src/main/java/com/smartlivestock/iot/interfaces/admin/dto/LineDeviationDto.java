package com.smartlivestock.iot.interfaces.admin.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * One per-point deviation of a LINE test (NIX-68, spec §7.4), served by
 * /tests/{id}/line-report/deviations in ascending time order.
 */
public record LineDeviationDto(
    int sequenceNo,
    Instant recordedAt,
    BigDecimal lng,
    BigDecimal lat,
    BigDecimal deviationM,
    int segmentNo
) {}
