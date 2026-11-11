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
        l.setType(ScenarioType.fromDbValue(e.getType()));
        l.setPeriodStart(e.getPeriodStart());
        l.setPeriodEnd(e.getPeriodEnd());
        l.setSource(LabelSource.valueOf(e.getSource()));
        l.setVerdict(e.getVerdict());
        l.setRefAlertId(e.getRefAlertId());
        l.setSeverity(e.getSeverity() != null ? e.getSeverity().doubleValue() : 0.0);
        l.setLabeledBy(e.getLabeledBy());
        l.setLabeledAt(e.getLabeledAt());
        l.setNote(e.getNote());
        l.setCreatedAt(e.getCreatedAt());
        return l;
    }

    public static GroundTruthLabelJpaEntity toEntity(GroundTruthLabel l) {
        GroundTruthLabelJpaEntity e = new GroundTruthLabelJpaEntity();
        e.setId(l.getId());
        e.setLivestockId(l.getLivestockId());
        e.setType(l.getType().getDbValue());
        e.setPeriodStart(l.getPeriodStart());
        e.setPeriodEnd(l.getPeriodEnd());
        e.setSource(l.getSource().name());
        e.setVerdict(l.getVerdict());
        e.setRefAlertId(l.getRefAlertId());
        e.setSeverity(BigDecimal.valueOf(l.getSeverity()));
        e.setLabeledBy(l.getLabeledBy());
        e.setLabeledAt(l.getLabeledAt());
        e.setNote(l.getNote());
        // Round-trip the audit timestamp: on the UPDATE path (verdict flip)
        // the rebuilt entity is merged over the managed one — a missing
        // createdAt would overwrite the NOT NULL column with NULL.
        e.setCreatedAt(l.getCreatedAt());
        return e;
    }
}
