package com.smartlivestock.ranch.domain.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.*;

class LivestockTest {

    private Livestock createLivestock() {
        return new Livestock(
            1L,    // farmId
            "LS-001",  // livestockCode
            "安格斯",  // breed
            "male",    // gender
            LocalDate.of(2023, 3, 15), // birthDate
            new BigDecimal("450.5")    // weight
        );
    }

    @Test
    void shouldCreateLivestockWithDefaults() {
        Livestock livestock = createLivestock();

        assertThat(livestock.getFarmId()).isEqualTo(1L);
        assertThat(livestock.getLivestockCode()).isEqualTo("LS-001");
        assertThat(livestock.getBreed()).isEqualTo("安格斯");
        assertThat(livestock.getGender()).isEqualTo("male");
        assertThat(livestock.getBirthDate()).isEqualTo(LocalDate.of(2023, 3, 15));
        assertThat(livestock.getWeight()).isEqualByComparingTo(new BigDecimal("450.5"));
        assertThat(livestock.getHealthStatus()).isEqualTo(HealthStatus.HEALTHY);
        assertThat(livestock.getLastLatitude()).isNull();
        assertThat(livestock.getLastLongitude()).isNull();
        assertThat(livestock.getLastPositionAt()).isNull();
    }

    @Test
    void shouldUpdatePosition() {
        Livestock livestock = createLivestock();

        livestock.updatePosition(new BigDecimal("28.245"), new BigDecimal("112.850"));

        assertThat(livestock.getLastLatitude()).isEqualByComparingTo(new BigDecimal("28.245"));
        assertThat(livestock.getLastLongitude()).isEqualByComparingTo(new BigDecimal("112.850"));
        assertThat(livestock.getLastPositionAt()).isNotNull();
    }

    @Test
    void shouldTransitionHealthStatus() {
        Livestock livestock = createLivestock();
        assertThat(livestock.getHealthStatus()).isEqualTo(HealthStatus.HEALTHY);

        livestock.markWarning();
        assertThat(livestock.getHealthStatus()).isEqualTo(HealthStatus.WARNING);

        livestock.markCritical();
        assertThat(livestock.getHealthStatus()).isEqualTo(HealthStatus.CRITICAL);

        livestock.markHealthy();
        assertThat(livestock.getHealthStatus()).isEqualTo(HealthStatus.HEALTHY);
    }
}
