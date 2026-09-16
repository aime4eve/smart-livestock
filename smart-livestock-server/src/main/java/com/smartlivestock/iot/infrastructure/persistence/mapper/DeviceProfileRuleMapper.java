package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.DeviceProfileRule;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.infrastructure.persistence.entity.DeviceProfileRuleJpaEntity;

public final class DeviceProfileRuleMapper {

    private DeviceProfileRuleMapper() {}

    public static DeviceProfileRuleJpaEntity toJpaEntity(DeviceProfileRule rule) {
        DeviceProfileRuleJpaEntity jpa = new DeviceProfileRuleJpaEntity();
        jpa.setId(rule.getId());
        jpa.setProfileName(rule.getProfileName());
        jpa.setDeviceType(rule.getDeviceType() != null ? rule.getDeviceType().name() : null);
        jpa.setEnabled(rule.isEnabled());
        jpa.setRemark(rule.getRemark());
        jpa.setCreatedBy(rule.getCreatedBy());
        jpa.setUpdatedBy(rule.getUpdatedBy());
        return jpa;
    }

    public static DeviceProfileRule toDomain(DeviceProfileRuleJpaEntity jpa) {
        DeviceProfileRule rule = new DeviceProfileRule();
        rule.setId(jpa.getId());
        rule.setProfileName(jpa.getProfileName());
        rule.setDeviceType(jpa.getDeviceType() != null
                ? DeviceType.valueOf(jpa.getDeviceType()) : null);
        rule.setEnabled(jpa.isEnabled());
        rule.setRemark(jpa.getRemark());
        rule.setCreatedBy(jpa.getCreatedBy());
        rule.setUpdatedBy(jpa.getUpdatedBy());
        rule.setCreatedAt(jpa.getCreatedAt());
        rule.setUpdatedAt(jpa.getUpdatedAt());
        return rule;
    }
}
