package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.SynthesisScenarioJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SynthesisScenarioJpaRepository extends JpaRepository<SynthesisScenarioJpaEntity, Long> {
    List<SynthesisScenarioJpaEntity> findByStatus(String status);
}
