package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.BehaviorFeatureContractJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BehaviorFeatureContractJpaRepository
        extends JpaRepository<BehaviorFeatureContractJpaEntity, String> {
}
