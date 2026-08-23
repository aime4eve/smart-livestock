package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "behavior_windows")
@Getter
@Setter
public class BehaviorWindowJpaEntity {
    @Id
    private UUID id;

    @Column(name = "dataset_id", nullable = false)
    private UUID datasetId;

    @Column(name = "episode_id", nullable = false)
    private UUID episodeId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "window_start", nullable = false)
    private Instant windowStart;

    @Column(name = "window_end", nullable = false)
    private Instant windowEnd;

    @Column(name = "dominant_behavior", nullable = false, length = 20)
    private String dominantBehavior;

    @Column(name = "feature_version", nullable = false, length = 20)
    private String featureVersion;

    @Column(name = "feature_schema_hash", nullable = false, length = 64)
    private String featureSchemaHash;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "features", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> features;

    @Column(name = "input_quality", nullable = false, length = 20)
    private String inputQuality;

    @Column(name = "sampling_mode", nullable = false, length = 20)
    private String samplingMode;

    @Column(name = "model_compatible", nullable = false)
    private boolean modelCompatible;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
