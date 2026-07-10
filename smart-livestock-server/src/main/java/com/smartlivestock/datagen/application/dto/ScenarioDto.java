package com.smartlivestock.datagen.application.dto;

import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import java.time.Instant;
import java.util.List;

public record ScenarioDto(
        Long id, String name, String status, String type,
        Double penetrationRate, Instant windowStart, Instant windowEnd,
        Integer intervalSeconds, List<Long> targetLivestockIds
) {
    public static ScenarioDto from(SynthesisScenario s) {
        return new ScenarioDto(s.getId(), s.getName(), s.getStatus().name(),
                s.getType().getDbValue(), s.getPenetrationRate(),
                s.getWindowStart(), s.getWindowEnd(),
                s.getIntervalSeconds(), s.getTargetLivestockIds());
    }
}
