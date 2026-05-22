package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.FeatureGateMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaFeatureGateRepositoryImpl implements FeatureGateRepository {

    private final SpringDataFeatureGateRepository springDataRepo;

    @Override
    public Optional<FeatureGate> findByTierAndFeatureKey(String tier, String featureKey) {
        return springDataRepo.findByTierAndFeatureKey(tier, featureKey)
                .map(FeatureGateMapper::toDomain);
    }
}
