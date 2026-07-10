package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.FeatureGate;

import java.util.Optional;

public interface FeatureGateRepository {
    Optional<FeatureGate> findByTierAndFeatureKey(String tier, String featureKey);
}
