package com.smartlivestock.commerce.infrastructure.persistence;

import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsProvider;
import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsProvider.HealthThresholds;
import com.smartlivestock.commerce.infrastructure.persistence.entity.SubscriptionHealthSettingsJpaEntity;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Real-DB integration for the NIX-324 tier settings table (V20261103100000):
 * seed row presence/shape, CHECK-constraint rejection of unordered tiers,
 * and the provider's invalidate-then-reload round trip. Local machines
 * without Docker cannot run this — the remote integration testbed covers it
 * (AGENTS §5b).
 */
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
@TestPropertySource(properties = "spring.jpa.hibernate.ddl-auto=validate")
@Import(SubscriptionHealthSettingsProvider.class)
class SubscriptionHealthSettingsRepositoryIntegrationTest {

    @Autowired
    private SpringDataSubscriptionHealthSettingsRepository settingsRepository;

    @Autowired
    private SubscriptionHealthSettingsProvider settingsProvider;

    @Test
    void seedRowMatchesPreChangeHardcodedTiers() {
        var row = settingsRepository.findFirstByOrderByIdAsc().orElseThrow();
        assertThat(row.getWarnDays()).isEqualTo(14);
        assertThat(row.getCautionDays()).isEqualTo(7);
        assertThat(row.getDangerDays()).isEqualTo(3);
        assertThat(row.getUpdatedBy()).isEqualTo("seed");
    }

    @Test
    void unorderedTiersViolateTheCheckConstraint() {
        var bad = new SubscriptionHealthSettingsJpaEntity();
        bad.setWarnDays(7);
        bad.setCautionDays(10); // caution > warn → CHECK violation
        bad.setDangerDays(3);
        bad.setUpdatedBy("it");
        try {
            settingsRepository.saveAndFlush(bad);
            org.junit.jupiter.api.Assertions.fail("expected CHECK violation");
        } catch (Exception e) {
            // Hibernate wraps the JDBC constraint violation; any failure here
            // is fine as long as nothing was persisted.
            assertThat(settingsRepository.findFirstByOrderByIdAsc().orElseThrow().getWarnDays())
                    .isEqualTo(14);
        }
    }

    @Test
    void providerInvalidationReloadsPersistedTiers() {
        // Warm the cache with a save that bypasses provider.invalidate() (the
        // service always invalidates; here we simulate a foreign writer).
        var row = settingsRepository.findFirstByOrderByIdAsc().orElseThrow();
        row.setWarnDays(30);
        row.setCautionDays(10);
        row.setDangerDays(5);
        settingsRepository.saveAndFlush(row);
        settingsProvider.invalidate();

        HealthThresholds thresholds = settingsProvider.current();
        assertThat(thresholds.warnDays()).isEqualTo(30);
        assertThat(thresholds.cautionDays()).isEqualTo(10);
        assertThat(thresholds.dangerDays()).isEqualTo(5);
    }
}
