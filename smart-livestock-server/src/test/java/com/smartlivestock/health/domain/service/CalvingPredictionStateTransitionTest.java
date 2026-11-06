package com.smartlivestock.health.domain.service;

import com.smartlivestock.health.domain.service.CalvingPredictionService.AlertTransition;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Exhaustive table-driven lock of the extracted alert state machine (NIX-381
 * Task 4): every {@code prevColumnValue × newScore × hasActiveAlert}
 * combination against hand-derived expectations from the documented Task 3
 * semantics (persistence 2, persist 50, alert 70, release 55) — the semantic
 * contract the production orchestration and the simulation replayer share.
 * The expectations are written out literally (no re-derivation in the test),
 * so any drift in {@code transition} breaks the table.
 */
class CalvingPredictionStateTransitionTest {

    private CalvingPredictionService kernel;
    private CalvingPredictionProperties p;

    @BeforeEach
    void setUp() {
        kernel = new CalvingPredictionService();
        p = new CalvingPredictionProperties();
    }

    /** One expectation row, hand-derived from the documented semantics. */
    private record Row(Integer prev, int newScore, boolean hasActive,
                       Integer expectedColumn, boolean expectedRaise,
                       boolean expectedRelease, boolean expectedStoreRow) {
    }

    @Test
    void transition_exhaustiveCombinationTable_matchesDocumentedSemantics() {
        List<Row> rows = List.of(
                // prev = null (never scored): never crossed (persistence 2 needs a
                // prev >= alert), never alertActive -> the first crossing only
                // lands the score; a sub-persist score writes nothing at all.
                new Row(null, 45, false, null, false, false, false),
                new Row(null, 45, true, null, false, false, false),
                new Row(null, 59, false, 59, false, false, true),
                new Row(null, 59, true, 59, false, false, true),
                new Row(null, 65, false, 65, false, false, true),
                new Row(null, 65, true, 65, false, false, true),
                new Row(null, 71, false, 71, false, false, true),
                new Row(null, 71, true, 71, false, false, true),
                new Row(null, 80, false, 80, false, false, true),
                new Row(null, 80, true, 80, false, false, true),

                // prev = 45: sub-persist prev without a ticket; a further
                // sub-persist score resets the stale column, >= persist stores.
                // An ACTIVE ticket releases below 55 immediately.
                new Row(45, 45, false, null, false, false, false),
                new Row(45, 59, false, 59, false, false, true),
                new Row(45, 65, false, 65, false, false, true),
                new Row(45, 71, false, 71, false, false, true),
                new Row(45, 80, false, 80, false, false, true),
                new Row(45, 45, true, null, false, true, true),
                new Row(45, 59, true, 59, false, false, true),
                new Row(45, 65, true, 65, false, false, true),
                new Row(45, 71, true, 71, false, false, true),
                new Row(45, 80, true, 80, false, false, true),

                // prev = 65 (persisted but below the alert line): crossing still
                // impossible (persistence 2), hold band tracks the score.
                new Row(65, 45, false, null, false, false, false),
                new Row(65, 59, false, 59, false, false, true),
                new Row(65, 65, false, 65, false, false, true),
                new Row(65, 71, false, 71, false, false, true),
                new Row(65, 80, false, 80, false, false, true),
                new Row(65, 45, true, null, false, true, true),
                new Row(65, 59, true, 59, false, false, true),
                new Row(65, 65, true, 65, false, false, true),
                new Row(65, 71, true, 71, false, false, true),
                new Row(65, 80, true, 80, false, false, true),

                // prev = 72 (>= alert): a further >= alert score crosses.
                // Without a ticket that raise creates one; with a ticket the
                // band holds it (no re-raise, no release at 59).
                new Row(72, 45, false, null, false, false, false),
                new Row(72, 59, false, 59, false, false, true),
                new Row(72, 65, false, 65, false, false, true),
                new Row(72, 71, false, 71, true, false, true),
                new Row(72, 80, false, 80, true, false, true),
                new Row(72, 45, true, null, false, true, true),
                new Row(72, 59, true, 59, false, false, true),
                new Row(72, 65, true, 65, false, false, true),
                new Row(72, 71, true, 71, false, false, true),
                new Row(72, 80, true, 80, false, false, true));

        assertThat(rows).hasSize(4 * 5 * 2);
        for (Row row : rows) {
            AlertTransition transition = kernel.transition(row.prev(), row.newScore(),
                    row.hasActive(), p);
            assertThat(transition.newColumnValue())
                    .as("prev=%s new=%s hasActive=%s -> column", row.prev(), row.newScore(), row.hasActive())
                    .isEqualTo(row.expectedColumn());
            assertThat(transition.raise())
                    .as("prev=%s new=%s hasActive=%s -> raise", row.prev(), row.newScore(), row.hasActive())
                    .isEqualTo(row.expectedRaise());
            assertThat(transition.release())
                    .as("prev=%s new=%s hasActive=%s -> release", row.prev(), row.newScore(), row.hasActive())
                    .isEqualTo(row.expectedRelease());
            assertThat(transition.storeRow())
                    .as("prev=%s new=%s hasActive=%s -> storeRow", row.prev(), row.newScore(), row.hasActive())
                    .isEqualTo(row.expectedStoreRow());
        }
    }

    /**
     * alertPersistencePoints = 1: a single at/above-alert score crosses
     * without any previous column (the Task 3 "first crossing raises
     * immediately" switch); the other rows stay as in the main table.
     */
    @Test
    void transition_persistenceOne_singleCrossingRaisesWithoutPrev() {
        p.setAlertPersistencePoints(1);

        // First crossing with no column and no ticket -> raise.
        AlertTransition raise = kernel.transition(null, 71, false, p);
        assertThat(raise.newColumnValue()).isEqualTo(71);
        assertThat(raise.raise()).isTrue();
        assertThat(raise.release()).isFalse();
        assertThat(raise.storeRow()).isTrue();

        // First crossing with a ticket already active -> hold, never re-raise.
        AlertTransition hold = kernel.transition(null, 80, true, p);
        assertThat(hold.newColumnValue()).isEqualTo(80);
        assertThat(hold.raise()).isFalse();

        // Below persist stays silent even though persistence is 1.
        AlertTransition quiet = kernel.transition(null, 59, false, p);
        assertThat(quiet.newColumnValue()).isEqualTo(59);
        assertThat(quiet.raise()).isFalse();
        assertThat(quiet.storeRow()).isTrue();

        // Sub-persist with a ticket still releases (immediate hysteresis).
        AlertTransition release = kernel.transition(65, 45, true, p);
        assertThat(release.newColumnValue()).isNull();
        assertThat(release.release()).isTrue();
        assertThat(release.storeRow()).isTrue();
    }

    /**
     * The column-UPDATE guard: the write runs exactly when the stored value
     * changes — release/reset clear a non-null prev, the persist branch
     * stores a DIFFERENT score, same-value steady state skips the write.
     */
    @Test
    void storeColumn_writeOnlyWhenValueActuallyChanges() {
        // Release clears a stored column -> write.
        assertThat(kernel.transition(72, 45, true, p).storeColumn(72)).isTrue();
        // Reset of a stale prev -> write; no prev at all -> skip.
        assertThat(kernel.transition(65, 45, false, p).storeColumn(65)).isTrue();
        assertThat(kernel.transition(null, 45, false, p).storeColumn(null)).isFalse();
        // Persist branch: different score -> write; same score -> skip.
        assertThat(kernel.transition(null, 59, false, p).storeColumn(null)).isTrue();
        assertThat(kernel.transition(59, 59, true, p).storeColumn(59)).isFalse();
        // Raise (crossed, no ticket): column keeps the same score -> skip the
        // UPDATE, the raise itself is the commit.
        assertThat(kernel.transition(71, 71, false, p).storeColumn(71)).isFalse();
    }

    /**
     * crossedAlert mirrors the persistence rule directly — the caller uses it
     * to decide whether an ACTIVE-ticket lookup can matter at all (never-scored
     * heads below the alert line cost no lookup).
     */
    @Test
    void crossedAlert_persistenceRuleDecisionBoundary() {
        // Persistence 2: needs prev >= alert AND new >= alert.
        assertThat(kernel.crossedAlert(null, 80, p)).isFalse();
        assertThat(kernel.crossedAlert(65, 80, p)).isFalse();
        assertThat(kernel.crossedAlert(69, 80, p)).isFalse();
        assertThat(kernel.crossedAlert(70, 70, p)).isTrue();
        assertThat(kernel.crossedAlert(80, 69, p)).isFalse();

        // Persistence 1: the score alone decides.
        p.setAlertPersistencePoints(1);
        assertThat(kernel.crossedAlert(null, 70, p)).isTrue();
        assertThat(kernel.crossedAlert(null, 69, p)).isFalse();
        assertThat(kernel.crossedAlert(45, 80, p)).isTrue();
    }
}
