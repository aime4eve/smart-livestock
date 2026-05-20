package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.infrastructure.persistence.entity.FeatureGateJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SpringDataFeatureGateRepository extends JpaRepository<FeatureGateJpaEntity, Long> {
    Optional<FeatureGateJpaEntity> findByTierAndFeatureKey(String tier, String featureKey);
}
