package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeSplitAssignmentJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeSplitId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BehaviorEpisodeSplitAssignmentJpaRepository
        extends JpaRepository<BehaviorEpisodeSplitAssignmentJpaEntity, BehaviorEpisodeSplitId> {
    List<BehaviorEpisodeSplitAssignmentJpaEntity> findByIdDatasetId(UUID datasetId);
}
