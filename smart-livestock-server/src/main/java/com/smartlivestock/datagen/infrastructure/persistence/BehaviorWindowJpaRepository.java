package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorWindowJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BehaviorWindowJpaRepository
        extends JpaRepository<BehaviorWindowJpaEntity, UUID> {
    List<BehaviorWindowJpaEntity> findByDatasetIdOrderByWindowStartAsc(UUID datasetId);
}
