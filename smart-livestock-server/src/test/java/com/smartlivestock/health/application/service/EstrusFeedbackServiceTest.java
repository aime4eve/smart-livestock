package com.smartlivestock.health.application.service;

import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import com.smartlivestock.health.domain.model.EstrusScore;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.repository.EstrusScoreRepository;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DataIntegrityViolationException;

import java.lang.reflect.Field;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the estrus confirmation feedback labeling service
 * (NIX-286 contract v2): episode-backed verdict labels, idempotency and
 * reversal semantics, physiology audit-row upsert with the unique-index
 * race fallback, and the BREEDING_DERIVED weak-evidence linking.
 */
class EstrusFeedbackServiceTest {

    private static final Long FARM_ID = 1L;
    private static final Long LIVESTOCK_ID = 5L;
    private static final Long USER_ID = 9L;
    private static final Long ALERT_ID = 11L;

    /** Alert raised at T0; episodes are anchored around it. */
    private static final Instant T0 = Instant.parse("2026-11-10T08:00:00Z");

    private AlertRepository alertRepository;
    private EstrusScoreRepository estrusScoreRepository;
    private GroundTruthLabelRepository groundTruthLabelRepository;
    private PhysiologyEventJpaRepository physiologyEventRepository;
    private EstrusFeedbackService service;

    @BeforeEach
    void setUp() {
        alertRepository = mock(AlertRepository.class);
        estrusScoreRepository = mock(EstrusScoreRepository.class);
        groundTruthLabelRepository = mock(GroundTruthLabelRepository.class);
        physiologyEventRepository = mock(PhysiologyEventJpaRepository.class);
        service = new EstrusFeedbackService(alertRepository, estrusScoreRepository,
                groundTruthLabelRepository, physiologyEventRepository,
                mock(EstrusSeriesReplayer.class));
        // Label / event saves echo the argument with a simulated generated id.
        // Null-guarded: Mockito re-stubbing (when(save(any())) in a test)
        // re-runs this answer with a null argument (matcher placeholders),
        // which must not blow up.
        when(groundTruthLabelRepository.save(any())).thenAnswer(invocation -> {
            GroundTruthLabel label = invocation.getArgument(0);
            if (label != null) {
                label.setId(99L);
            }
            return label;
        });
        when(physiologyEventRepository.save(any())).thenAnswer(invocation -> {
            PhysiologyEventJpaEntity entity = invocation.getArgument(0);
            if (entity != null) {
                entity.setId(77L);
            }
            return entity;
        });
    }

    // ── Fixtures ────────────────────────────────────────────────

    private Alert estrusAlert() {
        Alert alert = new Alert(FARM_ID, LIVESTOCK_ID, null, AlertType.ESTRUS, null, "estrus");
        alert.setId(ALERT_ID);
        alert.setCreatedAt(T0);
        return alert;
    }

    private EstrusScore score(int value, Instant scoredAt) {
        EstrusScore score = new EstrusScore();
        score.setLivestockId(LIVESTOCK_ID);
        score.setScore(value);
        score.setScoredAt(scoredAt);
        return score;
    }

    private PhysiologyEventJpaEntity auditRow(long id) {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setId(id);
        entity.setLivestockId(LIVESTOCK_ID);
        entity.setEventType(PhysiologyEventType.ESTRUS_CONFIRM);
        entity.setSource(PhysiologySource.ALERT_CONFIRM);
        entity.setRefId(ALERT_ID);
        entity.setOccurredAt(T0);
        return entity;
    }

    // ── 1. Confirm happy path ───────────────────────────────────

    @Test
    void confirmWritesEpisodeBackedLabelAndAuditEvent() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        // One sub-threshold position (filtered) plus three ≥70 positions
        // within the 24h merge gap → a single episode [T2, T2+1h]. Input is
        // deliberately newest-first to prove the restore is order-agnostic.
        Instant t2 = T0.minusSeconds(3600);
        when(estrusScoreRepository.findByLivestockIdOrderByScoredAtDesc(eq(LIVESTOCK_ID), anyInt()))
                .thenReturn(List.of(
                        score(75, t2.plusSeconds(3600)),
                        score(90, t2.plusSeconds(1800)),
                        score(50, t2.minusSeconds(1800)),
                        score(85, t2)));

        EstrusFeedbackService.FeedbackResult result = service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID);

        assertThat(result.alertId()).isEqualTo(ALERT_ID);
        assertThat(result.verdict()).isEqualTo("CONFIRMED");
        assertThat(result.physiologyEventId()).isEqualTo(77L);
        assertThat(result.labelId()).isEqualTo(99L);
        assertThat(result.idempotent()).isFalse();

        ArgumentCaptor<PhysiologyEventJpaEntity> eventCaptor =
                ArgumentCaptor.forClass(PhysiologyEventJpaEntity.class);
        verify(physiologyEventRepository).save(eventCaptor.capture());
        PhysiologyEventJpaEntity event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(PhysiologyEventType.ESTRUS_CONFIRM);
        assertThat(event.getSource()).isEqualTo(PhysiologySource.ALERT_CONFIRM);
        assertThat(event.getLivestockId()).isEqualTo(LIVESTOCK_ID);
        assertThat(event.getRefId()).isEqualTo(ALERT_ID);
        assertThat(event.getOccurredAt()).isEqualTo(T0);
        assertThat(event.getCreatedBy()).isEqualTo(USER_ID);
        assertThat(event.getNote()).contains("confirmed", "alert #11");

        ArgumentCaptor<GroundTruthLabel> labelCaptor = ArgumentCaptor.forClass(GroundTruthLabel.class);
        verify(groundTruthLabelRepository).save(labelCaptor.capture());
        GroundTruthLabel label = labelCaptor.getValue();
        assertThat(label.getType()).isEqualTo(ScenarioType.ESTRUS);
        assertThat(label.getSource()).isEqualTo(LabelSource.MANUAL);
        assertThat(label.getVerdict()).isEqualTo("CONFIRMED");
        assertThat(label.getRefAlertId()).isEqualTo(ALERT_ID);
        assertThat(label.getPeriodStart()).isEqualTo(t2);
        assertThat(label.getPeriodEnd()).isEqualTo(t2.plusSeconds(3600));
        assertThat(label.getSeverity()).isEqualTo(1.0);
        assertThat(label.getLabeledBy()).isEqualTo(USER_ID);
        assertThat(label.getLabeledAt()).isNotNull();
        assertThat(label.getNote()).isEqualTo("alert #11 feedback");
    }

    // ── 2. Restore failure → point window ───────────────────────

    @Test
    void restoreFailureFallsBackToAlertPointWindow() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        when(estrusScoreRepository.findByLivestockIdOrderByScoredAtDesc(anyLong(), anyInt()))
                .thenThrow(new RuntimeException("restore boom"));

        service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID);

        ArgumentCaptor<GroundTruthLabel> labelCaptor = ArgumentCaptor.forClass(GroundTruthLabel.class);
        verify(groundTruthLabelRepository).save(labelCaptor.capture());
        assertThat(labelCaptor.getValue().getPeriodStart()).isEqualTo(T0);
        assertThat(labelCaptor.getValue().getPeriodEnd()).isEqualTo(T0);
    }

    // ── 3. Same-verdict repeat → idempotent, zero writes ────────

    @Test
    void sameVerdictRepeatIsIdempotentWithZeroWrites() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        GroundTruthLabel existing = new GroundTruthLabel();
        existing.setId(55L);
        existing.setVerdict("CONFIRMED");
        when(groundTruthLabelRepository.findActiveVerdictByRefAlertId(ALERT_ID))
                .thenReturn(Optional.of(existing));
        when(physiologyEventRepository.findByLivestockIdAndRefIdAndSource(
                LIVESTOCK_ID, ALERT_ID, PhysiologySource.ALERT_CONFIRM))
                .thenReturn(Optional.of(auditRow(77L)));

        EstrusFeedbackService.FeedbackResult result = service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID);

        assertThat(result.idempotent()).isTrue();
        assertThat(result.verdict()).isEqualTo("CONFIRMED");
        assertThat(result.labelId()).isEqualTo(55L);
        assertThat(result.physiologyEventId()).isEqualTo(77L);
        verify(groundTruthLabelRepository, never()).save(any());
        verify(physiologyEventRepository, never()).save(any());
    }

    // ── 4. Confirm → reject reversal ────────────────────────────

    @Test
    void flippedVerdictSupersedesOldRowAndInsertsNewOne() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        GroundTruthLabel oldRow = new GroundTruthLabel();
        oldRow.setId(55L);
        oldRow.setVerdict("CONFIRMED");
        when(groundTruthLabelRepository.findActiveVerdictByRefAlertId(ALERT_ID))
                .thenReturn(Optional.of(oldRow));
        when(physiologyEventRepository.findByLivestockIdAndRefIdAndSource(
                LIVESTOCK_ID, ALERT_ID, PhysiologySource.ALERT_CONFIRM))
                .thenReturn(Optional.of(auditRow(77L)));
        // Pure echo stub (no id-stamping): keeps the old row's own id so the
        // two save invocations stay distinguishable (GroundTruthLabel.equals
        // compares ids, and the setUp stub would stamp both rows alike).
        when(groundTruthLabelRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        EstrusFeedbackService.FeedbackResult result = service.submitFeedback(FARM_ID, ALERT_ID, false, USER_ID);

        assertThat(result.idempotent()).isFalse();
        assertThat(result.verdict()).isEqualTo("REJECTED");
        assertThat(result.physiologyEventId()).isEqualTo(77L);
        // Reversal: the old CONFIRMED row is marked SUPERSEDED first, then the
        // REJECTED row is inserted — same transaction, ordered writes (captor
        // values are recorded in invocation order).
        ArgumentCaptor<GroundTruthLabel> labelCaptor = ArgumentCaptor.forClass(GroundTruthLabel.class);
        verify(groundTruthLabelRepository, times(2)).save(labelCaptor.capture());
        assertThat(labelCaptor.getAllValues().get(0)).isSameAs(oldRow);
        assertThat(oldRow.getVerdict()).isEqualTo("SUPERSEDED");
        GroundTruthLabel newRow = labelCaptor.getAllValues().get(1);
        assertThat(newRow.getVerdict()).isEqualTo("REJECTED");
        assertThat(newRow.getSeverity()).isEqualTo(0.0);
        assertThat(newRow.getRefAlertId()).isEqualTo(ALERT_ID);
        // The audit row already exists → reused, never re-inserted.
        verify(physiologyEventRepository, never()).save(any());
    }

    /**
     * Idempotency matrix cell REJECTED → REJECTED: same flipped-once verdict
     * resubmitted — idempotent, zero writes (mirrors the CONFIRMED → CONFIRMED
     * cell of {@link #sameVerdictRepeatIsIdempotentWithZeroWrites()}).
     */
    @Test
    void rejectedRepeatIsAlsoIdempotentWithZeroWrites() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        GroundTruthLabel existing = new GroundTruthLabel();
        existing.setId(56L);
        existing.setVerdict("REJECTED");
        when(groundTruthLabelRepository.findActiveVerdictByRefAlertId(ALERT_ID))
                .thenReturn(Optional.of(existing));

        EstrusFeedbackService.FeedbackResult result = service.submitFeedback(FARM_ID, ALERT_ID, false, USER_ID);

        assertThat(result.idempotent()).isTrue();
        assertThat(result.verdict()).isEqualTo("REJECTED");
        assertThat(result.labelId()).isEqualTo(56L);
        verify(groundTruthLabelRepository, never()).save(any());
        verify(physiologyEventRepository, never()).save(any());
    }

    /**
     * Idempotency matrix cell REJECTED → CONFIRMED: re-confirming after a
     * rejection supersedes the REJECTED row and inserts a fresh CONFIRMED row
     * with full severity (mirror of
     * {@link #flippedVerdictSupersedesOldRowAndInsertsNewOne()}).
     */
    @Test
    void reconfirmAfterRejectSupersedesRejectedRow() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        GroundTruthLabel oldRow = new GroundTruthLabel();
        oldRow.setId(56L);
        oldRow.setVerdict("REJECTED");
        when(groundTruthLabelRepository.findActiveVerdictByRefAlertId(ALERT_ID))
                .thenReturn(Optional.of(oldRow));
        when(groundTruthLabelRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID);

        ArgumentCaptor<GroundTruthLabel> labelCaptor = ArgumentCaptor.forClass(GroundTruthLabel.class);
        verify(groundTruthLabelRepository, times(2)).save(labelCaptor.capture());
        assertThat(labelCaptor.getAllValues().get(0)).isSameAs(oldRow);
        assertThat(oldRow.getVerdict()).isEqualTo("SUPERSEDED");
        GroundTruthLabel newRow = labelCaptor.getAllValues().get(1);
        assertThat(newRow.getVerdict()).isEqualTo("CONFIRMED");
        assertThat(newRow.getSeverity()).isEqualTo(1.0);
    }

    // ── 5. Validation errors ────────────────────────────────────

    @Test
    void unknownAlertThrows404() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID))
                .isInstanceOf(ApiException.class)
                .extracting("code").isEqualTo(ErrorCode.RESOURCE_NOT_FOUND);
    }

    @Test
    void nonEstrusAlertThrows400() {
        Alert fenceAlert = estrusAlert();
        fenceAlert.setType(AlertType.TEMPERATURE_ABNORMAL);
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(fenceAlert));

        assertThatThrownBy(() -> service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID))
                .isInstanceOf(ApiException.class)
                .extracting("code").isEqualTo(ErrorCode.VALIDATION_ERROR);
    }

    @Test
    void crossFarmAlertThrows403() {
        Alert otherFarm = estrusAlert();
        otherFarm.setFarmId(2L);
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(otherFarm));

        assertThatThrownBy(() -> service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID))
                .isInstanceOf(ApiException.class)
                .extracting("code").isEqualTo(ErrorCode.AUTH_FORBIDDEN);
    }

    // ── 6. Unique-index race → re-read the winner ───────────────

    @Test
    void physiologyEventUniqueRaceRereadsExistingRow() {
        when(alertRepository.findById(ALERT_ID)).thenReturn(Optional.of(estrusAlert()));
        when(physiologyEventRepository.findByLivestockIdAndRefIdAndSource(
                LIVESTOCK_ID, ALERT_ID, PhysiologySource.ALERT_CONFIRM))
                // First call: the pre-check finds nothing; the save then hits
                // uq_physiology_alert_confirm; the fallback re-read (second
                // call) returns the committed winner.
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(auditRow(77L)));
        when(physiologyEventRepository.save(any()))
                .thenThrow(new DataIntegrityViolationException("uq_physiology_alert_confirm"));

        EstrusFeedbackService.FeedbackResult result = service.submitFeedback(FARM_ID, ALERT_ID, true, USER_ID);

        assertThat(result.physiologyEventId()).isEqualTo(77L);
        assertThat(result.idempotent()).isFalse();
        verify(physiologyEventRepository, times(2))
                .findByLivestockIdAndRefIdAndSource(LIVESTOCK_ID, ALERT_ID, PhysiologySource.ALERT_CONFIRM);
    }

    // ── 7. linkBreedingDerived ──────────────────────────────────

    @Test
    void breedingWindowDerivesLabelsWithoutVerdict() {
        Instant breedingAt = T0.plusSeconds(6 * 3600);
        Alert insideWindow = estrusAlert(); // createdAt = T0 ∈ [breedingAt−48h, breedingAt]
        Alert earlier = estrusAlert();
        earlier.setId(12L);
        earlier.setCreatedAt(breedingAt.minusSeconds(10 * 3600));
        when(alertRepository.findByLivestockIdAndTypeAndCreatedAtBetween(
                eq(LIVESTOCK_ID), eq(AlertType.ESTRUS), eq(breedingAt.minusSeconds(48 * 3600)), eq(breedingAt)))
                .thenReturn(List.of(insideWindow, earlier));

        int linked = service.linkBreedingDerived(LIVESTOCK_ID, breedingAt, USER_ID);

        assertThat(linked).isEqualTo(2);
        ArgumentCaptor<GroundTruthLabel> labelCaptor = ArgumentCaptor.forClass(GroundTruthLabel.class);
        verify(groundTruthLabelRepository, times(2)).save(labelCaptor.capture());
        for (GroundTruthLabel label : labelCaptor.getAllValues()) {
            assertThat(label.getType()).isEqualTo(ScenarioType.ESTRUS);
            assertThat(label.getSource()).isEqualTo(LabelSource.BREEDING_DERIVED);
            assertThat(label.getVerdict()).isNull();
            assertThat(label.getSeverity()).isEqualTo(0.0);
            assertThat(label.getLabeledBy()).isEqualTo(USER_ID);
            assertThat(label.getNote()).isEqualTo("derived from breeding record");
            assertThat(label.getPeriodStart()).isEqualTo(label.getPeriodEnd());
        }
        // Point windows anchored on each alert's createdAt.
        assertThat(labelCaptor.getAllValues().stream().map(GroundTruthLabel::getRefAlertId))
                .containsExactlyInAnyOrder(ALERT_ID, 12L);
    }

    @Test
    void breedingLinkingSkipsAlertsWithHumanVerdict() {
        Instant breedingAt = T0.plusSeconds(6 * 3600);
        Alert confirmed = estrusAlert();
        Alert unjudged = estrusAlert();
        unjudged.setId(12L);
        unjudged.setCreatedAt(breedingAt.minusSeconds(10 * 3600));
        when(alertRepository.findByLivestockIdAndTypeAndCreatedAtBetween(anyLong(), any(), any(), any()))
                .thenReturn(List.of(confirmed, unjudged));
        GroundTruthLabel humanRuling = new GroundTruthLabel();
        humanRuling.setVerdict("CONFIRMED");
        when(groundTruthLabelRepository.findActiveVerdictByRefAlertId(ALERT_ID))
                .thenReturn(Optional.of(humanRuling));
        when(groundTruthLabelRepository.findActiveVerdictByRefAlertId(12L))
                .thenReturn(Optional.empty());

        int linked = service.linkBreedingDerived(LIVESTOCK_ID, breedingAt, USER_ID);

        assertThat(linked).isEqualTo(1);
        ArgumentCaptor<GroundTruthLabel> labelCaptor = ArgumentCaptor.forClass(GroundTruthLabel.class);
        verify(groundTruthLabelRepository, times(1)).save(labelCaptor.capture());
        assertThat(labelCaptor.getValue().getRefAlertId()).isEqualTo(12L);
    }

    @Test
    void breedingLinkingContinuesPastSingleFailure() {
        Instant breedingAt = T0.plusSeconds(6 * 3600);
        Alert first = estrusAlert();
        Alert second = estrusAlert();
        second.setId(12L);
        second.setCreatedAt(breedingAt.minusSeconds(10 * 3600));
        when(alertRepository.findByLivestockIdAndTypeAndCreatedAtBetween(anyLong(), any(), any(), any()))
                .thenReturn(List.of(first, second));
        when(groundTruthLabelRepository.save(any()))
                .thenThrow(new IllegalStateException("label write boom"))
                .thenAnswer(invocation -> invocation.getArgument(0));

        int linked = service.linkBreedingDerived(LIVESTOCK_ID, breedingAt, USER_ID);

        // The first alert's write failed, the loop still processed the second.
        assertThat(linked).isEqualTo(1);
        verify(groundTruthLabelRepository, times(2)).save(any());
    }

    // ── 8. currentStage lock ────────────────────────────────────

    /**
     * ESTRUS_CONFIRM must never drive stage derivation: the
     * PhysiologyQueryService.STAGE_TYPES set (lactation/dry projection) stays
     * CALVING/DRY_OFF only, so the new audit rows cannot shift currentStage.
     */
    @Test
    void estrusConfirmIsNotAStageType() throws Exception {
        Field stageTypes = PhysiologyQueryService.class.getDeclaredField("STAGE_TYPES");
        stageTypes.setAccessible(true);
        @SuppressWarnings("unchecked")
        List<PhysiologyEventType> stageTypesValue = (List<PhysiologyEventType>) stageTypes.get(null);
        assertThat(stageTypesValue)
                .doesNotContain(PhysiologyEventType.ESTRUS_CONFIRM)
                .containsExactly(PhysiologyEventType.CALVING, PhysiologyEventType.DRY_OFF);
    }
}
