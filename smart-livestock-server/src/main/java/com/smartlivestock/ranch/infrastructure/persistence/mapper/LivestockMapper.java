package com.smartlivestock.ranch.infrastructure.persistence.mapper;

import com.smartlivestock.ranch.domain.model.HealthStatus;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.infrastructure.persistence.entity.LivestockJpaEntity;

public final class LivestockMapper {

    private LivestockMapper() {}

    public static LivestockJpaEntity toJpaEntity(Livestock livestock) {
        LivestockJpaEntity jpa = new LivestockJpaEntity();
        jpa.setId(livestock.getId());
        jpa.setFarmId(livestock.getFarmId());
        jpa.setLivestockCode(livestock.getLivestockCode());
        jpa.setBreed(livestock.getBreed());
        jpa.setGender(livestock.getGender());
        jpa.setBirthDate(livestock.getBirthDate());
        jpa.setWeight(livestock.getWeight());
        jpa.setHealthStatus(livestock.getHealthStatus().name());
        jpa.setLastLatitude(livestock.getLastLatitude());
        jpa.setLastLongitude(livestock.getLastLongitude());
        jpa.setLastPositionAt(livestock.getLastPositionAt());
        return jpa;
    }

    public static Livestock toDomain(LivestockJpaEntity jpa) {
        Livestock livestock = new Livestock();
        livestock.setId(jpa.getId());
        livestock.setFarmId(jpa.getFarmId());
        livestock.setLivestockCode(jpa.getLivestockCode());
        livestock.setBreed(jpa.getBreed());
        livestock.setGender(jpa.getGender());
        livestock.setBirthDate(jpa.getBirthDate());
        livestock.setWeight(jpa.getWeight());
        livestock.setHealthStatus(HealthStatus.valueOf(jpa.getHealthStatus()));
        livestock.reconstitutePosition(jpa.getLastLatitude(), jpa.getLastLongitude(), jpa.getLastPositionAt());
        return livestock;
    }
}
