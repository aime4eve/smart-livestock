package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorDatasetJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BehaviorDatasetJpaRepository
        extends JpaRepository<BehaviorDatasetJpaEntity, UUID> {
    Optional<BehaviorDatasetJpaEntity> findByDefinitionDigest(String definitionDigest);
}
