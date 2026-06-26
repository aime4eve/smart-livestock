package com.smartlivestock.datagen.domain.repository;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;

import java.util.List;
import java.util.Optional;

public interface SynthesisScenarioRepository {
    SynthesisScenario save(SynthesisScenario scenario);
    Optional<SynthesisScenario> findById(Long id);
    List<SynthesisScenario> findByStatus(ScenarioStatus status);
    List<SynthesisScenario> findAll();
}
