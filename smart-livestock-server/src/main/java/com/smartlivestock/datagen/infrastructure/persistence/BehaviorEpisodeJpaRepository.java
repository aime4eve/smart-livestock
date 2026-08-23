package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorEpisodeJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BehaviorEpisodeJpaRepository
        extends JpaRepository<BehaviorEpisodeJpaEntity, UUID> {
    List<BehaviorEpisodeJpaEntity> findByDatasetIdOrderByStartAtAsc(UUID datasetId);
}
