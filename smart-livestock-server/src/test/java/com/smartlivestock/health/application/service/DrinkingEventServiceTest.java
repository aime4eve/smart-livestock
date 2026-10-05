package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Pure unit tests for the statistics counting contract (revised spec §15.3):
 * {@code label != REJECTED && (source != ALGORITHM_CANDIDATE || label == CONFIRMED)}.
 * Detected rows count by default, rejected rows drop out, manual back-fills
 * count, and a candidate only counts once the ranch owner confirms it.
 */
class DrinkingEventServiceTest {

    private static DrinkingEventJpaEntity row(String source, DrinkingEventLabel label) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setSource(source);
        entity.setLabel(label);
        return entity;
    }

    @Test
    void detectedUnlabeledRowCounts() {
        assertThat(DrinkingEventService.isCounted(row("DATAGEN", DrinkingEventLabel.UNLABELED))).isTrue();
        assertThat(DrinkingEventService.isCounted(row("THINGSBOARD", DrinkingEventLabel.UNLABELED))).isTrue();
    }

    @Test
    void rejectedRowNeverCounts() {
        assertThat(DrinkingEventService.isCounted(row("DATAGEN", DrinkingEventLabel.REJECTED))).isFalse();
        assertThat(DrinkingEventService.isCounted(row(DrinkingEventSources.MANUAL, DrinkingEventLabel.REJECTED))).isFalse();
    }

    @Test
    void candidateCountsOnlyAfterConfirmation() {
        // Revised spec §15.3 (main-agent review ruling): a borderline
        // candidate stays outside the statistics until the ranch owner
        // confirms it (§15.2 "转正参与统计"); a rejected candidate never
        // counts, same as any rejected row.
        assertThat(DrinkingEventService.isCounted(
                row(DrinkingEventSources.ALGORITHM_CANDIDATE, DrinkingEventLabel.UNLABELED))).isFalse();
        assertThat(DrinkingEventService.isCounted(
                row(DrinkingEventSources.ALGORITHM_CANDIDATE, DrinkingEventLabel.CONFIRMED))).isTrue();
        assertThat(DrinkingEventService.isCounted(
                row(DrinkingEventSources.ALGORITHM_CANDIDATE, DrinkingEventLabel.REJECTED))).isFalse();
    }

    @Test
    void manualBackFillCounts() {
        assertThat(DrinkingEventService.isCounted(
                row(DrinkingEventSources.MANUAL, DrinkingEventLabel.CONFIRMED))).isTrue();
    }
}
