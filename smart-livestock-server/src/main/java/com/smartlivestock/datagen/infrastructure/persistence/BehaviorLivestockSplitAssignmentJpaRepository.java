package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorLivestockSplitAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorLivestockSplitId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BehaviorLivestockSplitAssignmentJpaRepository
        extends JpaRepository<BehaviorLivestockSplitAssignmentJpaEntity, BehaviorLivestockSplitId> {
    List<BehaviorLivestockSplitAssignmentJpaEntity> findByDatasetId(UUID datasetId);
}
