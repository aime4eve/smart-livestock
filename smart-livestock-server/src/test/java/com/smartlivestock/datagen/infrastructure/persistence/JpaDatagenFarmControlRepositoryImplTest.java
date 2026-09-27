package com.smartlivestock.datagen.infrastructure.persistence;

import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.infrastructure.persistence.entity.DatagenFarmControlJpaEntity;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JpaDatagenFarmControlRepositoryImplTest {
    @Mock private DatagenFarmControlJpaRepository jpaRepository;
    @Mock private EntityManager entityManager;
    @Mock private Query insertQuery;

    private JpaDatagenFarmControlRepositoryImpl repository;

    @BeforeEach
    void setUp() {
        repository = new JpaDatagenFarmControlRepositoryImpl(jpaRepository);
        ReflectionTestUtils.setField(repository, "entityManager", entityManager);
    }

    @Test
    void ensureByFarmId_repointsLegacyControlToDefaultScenario() {
        DatagenFarmControlJpaEntity entity = entity(2L);
        when(entityManager.createNativeQuery(anyString())).thenReturn(insertQuery);
        when(insertQuery.setParameter(anyString(), any())).thenReturn(insertQuery);
        when(jpaRepository.findByFarmIdForUpdate(1L)).thenReturn(Optional.of(entity));
        when(jpaRepository.findById(9L)).thenReturn(Optional.of(entity));
        when(jpaRepository.save(entity)).thenReturn(entity);

        DatagenFarmControl control = repository.ensureByFarmId(2L, 1L, 1L);

        assertEquals(1L, control.getScenarioId());
        verify(jpaRepository).save(entity);
    }

    @Test
    void ensureByFarmId_keepsCurrentScenario() {
        DatagenFarmControlJpaEntity entity = entity(1L);
        when(entityManager.createNativeQuery(anyString())).thenReturn(insertQuery);
        when(insertQuery.setParameter(anyString(), any())).thenReturn(insertQuery);
        when(jpaRepository.findByFarmIdForUpdate(1L)).thenReturn(Optional.of(entity));

        repository.ensureByFarmId(2L, 1L, 1L);

        verify(jpaRepository, never()).save(entity);
    }

    private DatagenFarmControlJpaEntity entity(Long scenarioId) {
        DatagenFarmControlJpaEntity entity = new DatagenFarmControlJpaEntity();
        entity.setId(9L);
        entity.setTenantId(2L);
        entity.setFarmId(1L);
        entity.setScenarioId(scenarioId);
        return entity;
    }
}
