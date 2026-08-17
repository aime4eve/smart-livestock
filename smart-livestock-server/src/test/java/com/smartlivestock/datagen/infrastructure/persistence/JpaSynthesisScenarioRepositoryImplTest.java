package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.infrastructure.persistence.entity.SynthesisScenarioJpaEntity;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JpaSynthesisScenarioRepositoryImplTest {

    @Mock private SynthesisScenarioJpaRepository jpaRepository;
    @InjectMocks private JpaSynthesisScenarioRepositoryImpl repository;

    @Test
    void save_existingScenario_preservesCreatedAt() {
        Instant createdAt = Instant.parse("2026-06-26T14:42:29Z");
        SynthesisScenarioJpaEntity existing = new SynthesisScenarioJpaEntity();
        existing.setId(1L);
        existing.setCreatedAt(createdAt);

        SynthesisScenario scenario = new SynthesisScenario();
        scenario.setId(1L);
        scenario.setName("默认持续合成");
        scenario.setStatus(ScenarioStatus.RUNNING);
        scenario.setType(ScenarioType.NORMAL);
        scenario.setPenetrationRate(1.0);
        scenario.setWindowStart(Instant.now().minusSeconds(60));
        scenario.setWindowEnd(Instant.now().plusSeconds(3600));
        scenario.setIntervalSeconds(30);

        when(jpaRepository.findById(1L)).thenReturn(Optional.of(existing));
        when(jpaRepository.save(argThat(entity -> entity.getId().equals(1L)))).thenReturn(existing);

        repository.save(scenario);

        assertEquals(createdAt, existing.getCreatedAt());
        assertEquals(ScenarioStatus.RUNNING.name(), existing.getStatus());
    }
}
