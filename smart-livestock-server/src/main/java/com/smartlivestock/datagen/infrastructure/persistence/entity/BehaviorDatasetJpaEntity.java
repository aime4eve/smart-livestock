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
@Table(name = "behavior_datasets")
@Getter
@Setter
public class BehaviorDatasetJpaEntity {
    @Id
    private UUID id;

    @Column(name = "scenario_id", nullable = false, length = 100)
    private String scenarioId;

    @Column(name = "seed", nullable = false)
    private long seed;

    @Column(name = "generator_version", nullable = false, length = 40)
    private String generatorVersion;

    @Column(name = "data_source", nullable = false, length = 30)
    private String dataSource;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "definition_digest", nullable = false, length = 64)
    private String definitionDigest;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "manifest", nullable = false, columnDefinition = "jsonb")
    private Map<String, Object> manifest;

    @Column(name = "start_at", nullable = false)
    private Instant startAt;

    @Column(name = "end_at", nullable = false)
    private Instant endAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
