package com.smartlivestock.health.infrastructure.persistence.mapper;

import com.smartlivestock.health.domain.model.*;
import com.smartlivestock.health.infrastructure.persistence.entity.*;

public final class HealthMapper {

    private HealthMapper() {}

    // ── TemperatureLog ──────────────────────────────────────────

    public static TemperatureLog toDomain(TemperatureLogJpaEntity e) {
        TemperatureLog d = new TemperatureLog();
        d.setId(e.getId());
        d.setLivestockId(e.getLivestockId());
        d.setDeviceId(e.getDeviceId());
        d.setTemperature(e.getTemperature());
        d.setBaselineTemp(e.getBaselineTemp());
        d.setDelta(e.getDelta());
        d.setRecordedAt(e.getRecordedAt());
        d.setCreatedAt(e.getCreatedAt());
        return d;
    }

    public static TemperatureLogJpaEntity toJpa(TemperatureLog d) {
        TemperatureLogJpaEntity e = new TemperatureLogJpaEntity();
        e.setId(d.getId());
        e.setLivestockId(d.getLivestockId());
        e.setDeviceId(d.getDeviceId());
        e.setTemperature(d.getTemperature());
        e.setBaselineTemp(d.getBaselineTemp());
        e.setRecordedAt(d.getRecordedAt());
        e.setCreatedAt(d.getCreatedAt());
        return e;
    }

    // ── RumenMotilityLog ────────────────────────────────────────

    public static RumenMotilityLog toDomain(RumenMotilityLogJpaEntity e) {
        RumenMotilityLog d = new RumenMotilityLog();
        d.setId(e.getId());
        d.setLivestockId(e.getLivestockId());
        d.setDeviceId(e.getDeviceId());
        d.setFrequency(e.getFrequency());
        d.setIntensity(e.getIntensity());
        d.setRecordedAt(e.getRecordedAt());
        d.setCreatedAt(e.getCreatedAt());
        return d;
    }

    public static RumenMotilityLogJpaEntity toJpa(RumenMotilityLog d) {
        RumenMotilityLogJpaEntity e = new RumenMotilityLogJpaEntity();
        e.setId(d.getId());
        e.setLivestockId(d.getLivestockId());
        e.setDeviceId(d.getDeviceId());
        e.setFrequency(d.getFrequency());
        e.setIntensity(d.getIntensity());
        e.setRecordedAt(d.getRecordedAt());
        e.setCreatedAt(d.getCreatedAt());
        return e;
    }

    // ── ActivityLog ─────────────────────────────────────────────

    public static ActivityLog toDomain(ActivityLogJpaEntity e) {
        ActivityLog d = new ActivityLog();
        d.setId(e.getId());
        d.setLivestockId(e.getLivestockId());
        d.setDeviceId(e.getDeviceId());
        d.setStepCount(e.getStepCount());
        d.setActivityIndex(e.getActivityIndex());
        d.setDistanceMeters(e.getDistanceMeters());
        d.setRecordedAt(e.getRecordedAt());
        d.setCreatedAt(e.getCreatedAt());
        return d;
    }

    public static ActivityLogJpaEntity toJpa(ActivityLog d) {
        ActivityLogJpaEntity e = new ActivityLogJpaEntity();
        e.setId(d.getId());
        e.setLivestockId(d.getLivestockId());
        e.setDeviceId(d.getDeviceId());
        e.setStepCount(d.getStepCount());
        e.setActivityIndex(d.getActivityIndex());
        e.setDistanceMeters(d.getDistanceMeters());
        e.setRecordedAt(d.getRecordedAt());
        e.setCreatedAt(d.getCreatedAt());
        return e;
    }

    // ── EstrusScore ─────────────────────────────────────────────

    public static EstrusScore toDomain(EstrusScoreJpaEntity e) {
        EstrusScore d = new EstrusScore();
        d.setId(e.getId());
        d.setFarmId(e.getFarmId());
        d.setLivestockId(e.getLivestockId());
        d.setScore(e.getScore());
        d.setStepIncreasePercent(e.getStepIncreasePercent());
        d.setTempDelta(e.getTempDelta());
        d.setDistanceDelta(e.getDistanceDelta());
        d.setAdvice(e.getAdvice());
        d.setScoredAt(e.getScoredAt());
        d.setCreatedAt(e.getCreatedAt());
        return d;
    }

    public static EstrusScoreJpaEntity toJpa(EstrusScore d) {
        EstrusScoreJpaEntity e = new EstrusScoreJpaEntity();
        e.setId(d.getId());
        e.setFarmId(d.getFarmId());
        e.setLivestockId(d.getLivestockId());
        e.setScore(d.getScore());
        e.setStepIncreasePercent(d.getStepIncreasePercent());
        e.setTempDelta(d.getTempDelta());
        e.setDistanceDelta(d.getDistanceDelta());
        e.setAdvice(d.getAdvice());
        e.setScoredAt(d.getScoredAt());
        e.setCreatedAt(d.getCreatedAt());
        return e;
    }

    // ── HealthSnapshot ──────────────────────────────────────────

    public static HealthSnapshot toDomain(HealthSnapshotJpaEntity e) {
        HealthSnapshot d = new HealthSnapshot();
        d.setId(e.getId());
        d.setLivestockId(e.getLivestockId());
        d.setFarmId(e.getFarmId());
        d.setBaselineTemp(e.getBaselineTemp());
        d.setCurrentTemp(e.getCurrentTemp());
        d.setTempStatus(TempStatus.valueOf(e.getTempStatus()));
        d.setMotilityBaseline(e.getMotilityBaseline());
        d.setCurrentMotility(e.getCurrentMotility());
        d.setMotilityStatus(MotilityStatus.valueOf(e.getMotilityStatus()));
        d.setEstrusScore(e.getEstrusScore());
        d.setActivityStatus(ActivityStatus.valueOf(e.getActivityStatus()));
        d.setLastAssessedAt(e.getLastAssessedAt());
        d.setCreatedAt(e.getCreatedAt());
        d.setUpdatedAt(e.getUpdatedAt());
        d.setAiAnomalyScore(e.getAiAnomalyScore());
        d.setAiAnomalyType(e.getAiAnomalyType());
        d.setAiAssessedAt(e.getAiAssessedAt());
        return d;
    }

    public static HealthSnapshotJpaEntity toJpa(HealthSnapshot d) {
        HealthSnapshotJpaEntity e = new HealthSnapshotJpaEntity();
        e.setId(d.getId());
        e.setLivestockId(d.getLivestockId());
        e.setFarmId(d.getFarmId());
        e.setBaselineTemp(d.getBaselineTemp());
        e.setCurrentTemp(d.getCurrentTemp());
        e.setTempStatus(d.getTempStatus().name());
        e.setMotilityBaseline(d.getMotilityBaseline());
        e.setCurrentMotility(d.getCurrentMotility());
        e.setMotilityStatus(d.getMotilityStatus().name());
        e.setEstrusScore(d.getEstrusScore());
        e.setActivityStatus(d.getActivityStatus().name());
        e.setLastAssessedAt(d.getLastAssessedAt());
        e.setCreatedAt(d.getCreatedAt());
        e.setUpdatedAt(d.getUpdatedAt());
        e.setAiAnomalyScore(d.getAiAnomalyScore());
        e.setAiAnomalyType(d.getAiAnomalyType());
        e.setAiAssessedAt(d.getAiAssessedAt());
        return e;
    }

    // ── ContactTrace ────────────────────────────────────────────

    public static ContactTrace toDomain(ContactTraceJpaEntity e) {
        ContactTrace d = new ContactTrace();
        d.setId(e.getId());
        d.setFarmId(e.getFarmId());
        d.setFromLivestockId(e.getFromLivestockId());
        d.setToLivestockId(e.getToLivestockId());
        d.setProximityMeters(e.getProximityMeters());
        d.setContactDurationMinutes(e.getContactDurationMinutes());
        d.setLastContactAt(e.getLastContactAt());
        d.setCreatedAt(e.getCreatedAt());
        d.setDiseaseType(e.getDiseaseType());
        d.setMarkedAt(e.getMarkedAt());
        d.setRiskScore(e.getRiskScore());
        d.setRiskLevel(e.getRiskLevel());
        return d;
    }

    public static ContactTraceJpaEntity toJpa(ContactTrace d) {
        ContactTraceJpaEntity e = new ContactTraceJpaEntity();
        e.setId(d.getId());
        e.setFarmId(d.getFarmId());
        e.setFromLivestockId(d.getFromLivestockId());
        e.setToLivestockId(d.getToLivestockId());
        e.setProximityMeters(d.getProximityMeters());
        e.setContactDurationMinutes(d.getContactDurationMinutes());
        e.setLastContactAt(d.getLastContactAt());
        e.setCreatedAt(d.getCreatedAt());
        e.setDiseaseType(d.getDiseaseType());
        e.setMarkedAt(d.getMarkedAt());
        e.setRiskScore(d.getRiskScore());
        e.setRiskLevel(d.getRiskLevel());
        return e;
    }
}
