package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import com.smartlivestock.datagen.infrastructure.persistence.entity.SynthesisScenarioJpaEntity;
import com.smartlivestock.datagen.infrastructure.persistence.mapper.SynthesisScenarioMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
@RequiredArgsConstructor
public class JpaSynthesisScenarioRepositoryImpl implements SynthesisScenarioRepository {
    private final SynthesisScenarioJpaRepository jpaRepository;

    @Override
    public SynthesisScenario save(SynthesisScenario scenario) {
        SynthesisScenarioJpaEntity entity = SynthesisScenarioMapper.toEntity(scenario);
        entity = jpaRepository.save(entity);
        return SynthesisScenarioMapper.toDomain(entity);
    }

    @Override
    public Optional<SynthesisScenario> findById(Long id) {
        return jpaRepository.findById(id).map(SynthesisScenarioMapper::toDomain);
    }

    @Override
    public List<SynthesisScenario> findByStatus(ScenarioStatus status) {
        return jpaRepository.findByStatus(status.name()).stream()
            .map(SynthesisScenarioMapper::toDomain).toList();
    }

    @Override
    public List<SynthesisScenario> findAll() {
        return jpaRepository.findAll().stream()
            .map(SynthesisScenarioMapper::toDomain).toList();
    }
}
