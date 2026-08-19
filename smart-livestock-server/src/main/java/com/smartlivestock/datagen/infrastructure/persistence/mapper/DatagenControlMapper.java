package com.smartlivestock.datagen.infrastructure.persistence.mapper;

import com.smartlivestock.datagen.domain.model.DatagenDeviceAssignment;
import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenDeviceAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenFarmControlJpaEntity;

public final class DatagenControlMapper {
    private DatagenControlMapper() {}

    public static DatagenFarmControl toDomain(DatagenFarmControlJpaEntity entity) {
        DatagenFarmControl control = new DatagenFarmControl();
        control.setId(entity.getId());
        control.setTenantId(entity.getTenantId());
        control.setFarmId(entity.getFarmId());
        control.setScenarioId(entity.getScenarioId());
        control.setEnabled(entity.isEnabled());
        control.setRules(entity.getRules());
        control.setCreatedAt(entity.getCreatedAt());
        control.setUpdatedAt(entity.getUpdatedAt());
        return control;
    }

    public static DatagenFarmControlJpaEntity toEntity(
            DatagenFarmControl control, DatagenFarmControlJpaEntity existing) {
        DatagenFarmControlJpaEntity entity =
                existing != null ? existing : new DatagenFarmControlJpaEntity();
        entity.setId(control.getId());
        entity.setTenantId(control.getTenantId());
        entity.setFarmId(control.getFarmId());
        entity.setScenarioId(control.getScenarioId());
        entity.setEnabled(control.isEnabled());
        entity.setRules(control.getRules());
        return entity;
    }

    public static DatagenDeviceAssignment toDomain(DatagenDeviceAssignmentJpaEntity entity) {
        DatagenDeviceAssignment assignment = new DatagenDeviceAssignment();
        assignment.setId(entity.getId());
        assignment.setControlId(entity.getControlId());
        assignment.setDeviceId(entity.getDeviceId());
        assignment.setFirstAssignedAt(entity.getFirstAssignedAt());
        assignment.setCreatedAt(entity.getCreatedAt());
        assignment.setRemovedAt(entity.getRemovedAt());
        return assignment;
    }

    public static DatagenDeviceAssignmentJpaEntity toEntity(
            DatagenDeviceAssignment assignment, DatagenDeviceAssignmentJpaEntity existing) {
        DatagenDeviceAssignmentJpaEntity entity =
                existing != null ? existing : new DatagenDeviceAssignmentJpaEntity();
        entity.setId(assignment.getId());
        entity.setControlId(assignment.getControlId());
        entity.setDeviceId(assignment.getDeviceId());
        entity.setFirstAssignedAt(assignment.getFirstAssignedAt());
        entity.setRemovedAt(assignment.getRemovedAt());
        return entity;
    }
}
