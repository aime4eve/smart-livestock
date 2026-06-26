package com.smartlivestock.datagen.infrastructure.persistence.mapper;

import com.smartlivestock.datagen.domain.model.*;
import com.smartlivestock.datagen.infrastructure.persistence.entity.GroundTruthLabelJpaEntity;

import java.math.BigDecimal;

public class GroundTruthLabelMapper {

    public static GroundTruthLabel toDomain(GroundTruthLabelJpaEntity e) {
        if (e == null) return null;
        GroundTruthLabel l = new GroundTruthLabel();
        l.setId(e.getId());
        l.setLivestockId(e.getLivestockId());
        l.setPattern(AnomalyPattern.fromDbValue(e.getPattern()));
        l.setScenarioType(e.getScenarioType() != null ? ScenarioType.valueOf(e.getScenarioType()) : ScenarioType.HEALTH);
        l.setPeriodStart(e.getPeriodStart());
        l.setPeriodEnd(e.getPeriodEnd());
        l.setSource(LabelSource.valueOf(e.getSource()));
        l.setSeverity(e.getSeverity() != null ? e.getSeverity().doubleValue() : 0.0);
        l.setLabeledBy(e.getLabeledBy());
        l.setLabeledAt(e.getLabeledAt());
        l.setNote(e.getNote());
        return l;
    }

    public static GroundTruthLabelJpaEntity toEntity(GroundTruthLabel l) {
        GroundTruthLabelJpaEntity e = new GroundTruthLabelJpaEntity();
        e.setId(l.getId());
        e.setLivestockId(l.getLivestockId());
        e.setPattern(l.getPattern().getDbValue());
        e.setScenarioType(l.getScenarioType().name());
        e.setPeriodStart(l.getPeriodStart());
        e.setPeriodEnd(l.getPeriodEnd());
        e.setSource(l.getSource().name());
        e.setSeverity(BigDecimal.valueOf(l.getSeverity()));
        e.setLabeledBy(l.getLabeledBy());
        e.setLabeledAt(l.getLabeledAt());
        e.setNote(l.getNote());
        return e;
    }
}
