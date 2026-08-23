package com.smartlivestock.datagen.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "behavior_livestock_split_assignments")
@Getter
@Setter
public class BehaviorLivestockSplitAssignmentJpaEntity {
    @EmbeddedId
    private BehaviorLivestockSplitId id;

    @Column(name = "dataset_split", nullable = false, length = 12)
    private String datasetSplit;

    @Column(name = "assigned_by")
    private Long assignedBy;

    @Column(name = "assigned_at", nullable = false)
    private Instant assignedAt;
}
