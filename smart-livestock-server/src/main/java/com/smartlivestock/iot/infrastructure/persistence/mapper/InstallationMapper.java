package com.smartlivestock.iot.infrastructure.persistence.mapper;

import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.infrastructure.persistence.entity.InstallationJpaEntity;

public final class InstallationMapper {

    private InstallationMapper() {}

    public static InstallationJpaEntity toJpaEntity(Installation installation) {
        InstallationJpaEntity jpa = new InstallationJpaEntity();
        jpa.setId(installation.getId());
        jpa.setDeviceId(installation.getDeviceId());
        jpa.setLivestockId(installation.getLivestockId());
        jpa.setInstalledAt(installation.getInstalledAt());
        jpa.setRemovedAt(installation.getRemovedAt());
        jpa.setOperatorId(installation.getOperatorId());
        return jpa;
    }

    public static Installation toDomain(InstallationJpaEntity jpa) {
        Installation installation = new Installation();
        installation.setId(jpa.getId());
        installation.setDeviceId(jpa.getDeviceId());
        installation.setLivestockId(jpa.getLivestockId());
        installation.reconstituteInstalledAt(jpa.getInstalledAt());
        installation.reconstituteRemovedAt(jpa.getRemovedAt());
        installation.setOperatorId(jpa.getOperatorId());
        return installation;
    }
}
