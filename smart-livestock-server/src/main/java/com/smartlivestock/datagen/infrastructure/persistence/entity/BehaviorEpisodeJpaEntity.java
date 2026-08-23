package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "behavior_episodes")
@Getter
@Setter
public class BehaviorEpisodeJpaEntity {
    @Id
    private UUID id;

    @Column(name = "dataset_id", nullable = false)
    private UUID datasetId;

    @Column(name = "tenant_id", nullable = false)
    private Long tenantId;

    @Column(name = "farm_id", nullable = false)
    private Long farmId;

    @Column(name = "livestock_id", nullable = false)
    private Long livestockId;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "dominant_behavior", nullable = false, length = 20)
    private String dominantBehavior;

    @Column(name = "start_at", nullable = false)
    private Instant startAt;

    @Column(name = "end_at", nullable = false)
    private Instant endAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
