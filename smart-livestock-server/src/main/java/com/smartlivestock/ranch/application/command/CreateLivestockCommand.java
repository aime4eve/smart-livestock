package com.smartlivestock.ranch.application.command;

import java.math.BigDecimal;
import java.time.LocalDate;

public record CreateLivestockCommand(
        Long farmId,
        String livestockCode,
        String breed,
        String gender,
        LocalDate birthDate,
        BigDecimal weight
) {}
