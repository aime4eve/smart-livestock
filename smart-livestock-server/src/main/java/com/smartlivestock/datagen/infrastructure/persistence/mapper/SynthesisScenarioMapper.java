package com.smartlivestock.datagen.infrastructure.persistence.mapper;

import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.infrastructure.persistence.entity.SynthesisScenarioJpaEntity;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

public class SynthesisScenarioMapper {

    public static SynthesisScenario toDomain(SynthesisScenarioJpaEntity e) {
        if (e == null) return null;
        SynthesisScenario s = new SynthesisScenario();
        s.setId(e.getId());
        s.setName(e.getName());
        s.setStatus(ScenarioStatus.valueOf(e.getStatus()));
        s.setScenarioType(e.getScenarioType() != null ? ScenarioType.valueOf(e.getScenarioType()) : ScenarioType.HEALTH);
        s.setPattern(AnomalyPattern.fromDbValue(e.getPattern()));
        s.setPenetrationRate(e.getPenetrationRate() != null ? e.getPenetrationRate() : 1.0);
        s.setWindowStart(e.getWindowStart());
        s.setWindowEnd(e.getWindowEnd());
        s.setIntervalSeconds(e.getIntervalSeconds() != null ? e.getIntervalSeconds() : 30);
        s.setTargetLivestockIds(parseLongArray(e.getTargetLivestockIds()));
        return s;
    }

    public static SynthesisScenarioJpaEntity toEntity(SynthesisScenario s) {
        SynthesisScenarioJpaEntity e = new SynthesisScenarioJpaEntity();
        e.setId(s.getId());
        e.setName(s.getName());
        e.setStatus(s.getStatus().name());
        e.setScenarioType(s.getScenarioType().name());
        e.setPattern(s.getPattern().getDbValue());
        e.setPenetrationRate(s.getPenetrationRate());
        e.setWindowStart(s.getWindowStart());
        e.setWindowEnd(s.getWindowEnd());
        e.setIntervalSeconds(s.getIntervalSeconds());
        e.setTargetLivestockIds(formatLongArray(s.getTargetLivestockIds()));
        return e;
    }

    private static List<Long> parseLongArray(String value) {
        if (value == null || value.isBlank()) return null;
        String cleaned = value.replaceAll("[{}\\[\\]\\s]", "");
        return Arrays.stream(cleaned.split(",")).filter(s -> !s.isEmpty())
            .map(Long::parseLong).collect(Collectors.toList());
    }

    private static String formatLongArray(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return null;
        return "{" + ids.stream().map(String::valueOf).collect(Collectors.joining(",")) + "}";
    }
}
