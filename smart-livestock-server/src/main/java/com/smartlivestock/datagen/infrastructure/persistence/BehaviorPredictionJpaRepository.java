package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorPredictionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface BehaviorPredictionJpaRepository
        extends JpaRepository<BehaviorPredictionJpaEntity, UUID> {
    List<BehaviorPredictionJpaEntity> findByWindowIdIn(Collection<UUID> windowIds);

    List<BehaviorPredictionJpaEntity> findByWindowIdInAndModelNameAndModelVersion(
            Collection<UUID> windowIds, String modelName, String modelVersion);
}
