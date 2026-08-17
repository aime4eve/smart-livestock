package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.infrastructure.persistence.entity.SynthesisScenarioJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SynthesisScenarioJpaRepository extends JpaRepository<SynthesisScenarioJpaEntity, Long> {
    List<SynthesisScenarioJpaEntity> findByStatus(String status);

    Optional<SynthesisScenarioJpaEntity> findFirstByNameOrderByIdAsc(String name);
}
