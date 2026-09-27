package com.smartlivestock.integration;

import com.smartlivestock.datagen.domain.model.DatagenFarmControl;
import com.smartlivestock.datagen.infrastructure.persistence.JpaDatagenFarmControlRepositoryImpl;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class DatagenFarmControlRepositoryIntegrationTest {

    @Autowired
    private JpaDatagenFarmControlRepositoryImpl repository;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void ensureByFarmIdRepointsLegacyControlToDefaultScenario() {
        Long defaultScenarioId = ((Number) entityManager
                .createNativeQuery("""
                        SELECT id FROM synthesis_scenarios
                        WHERE name = '默认持续合成'
                        LIMIT 1
                        """)
                .getSingleResult()).longValue();

        entityManager.createNativeQuery("""
                INSERT INTO synthesis_scenarios (
                    name, status, type, pattern, penetration_rate,
                    window_start, window_end, interval_seconds
                ) VALUES (
                    'datagen-repoint-integration-test', 'STOPPED', 'NORMAL', 'NORMAL',
                    1.00, NOW(), NOW() + INTERVAL '1 day', 30
                )
                """)
                .executeUpdate();
        entityManager.createNativeQuery("""
                UPDATE datagen_farm_controls
                SET scenario_id = (
                    SELECT id FROM synthesis_scenarios
                    WHERE name = 'datagen-repoint-integration-test'
                )
                WHERE farm_id = 1
                """)
                .executeUpdate();
        entityManager.flush();
        entityManager.clear();

        DatagenFarmControl control = repository.ensureByFarmId(1L, 1L, defaultScenarioId);

        assertNotNull(control);
        assertEquals(defaultScenarioId, control.getScenarioId());
        entityManager.flush();
        Number persistedScenarioId = (Number) entityManager
                .createNativeQuery("""
                        SELECT scenario_id FROM datagen_farm_controls WHERE farm_id = 1
                        """)
                .getSingleResult();
        assertEquals(defaultScenarioId, persistedScenarioId.longValue());
    }
}
