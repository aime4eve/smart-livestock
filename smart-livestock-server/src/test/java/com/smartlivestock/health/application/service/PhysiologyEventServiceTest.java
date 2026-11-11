package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventListResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventRequest;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventResponse;
import com.smartlivestock.health.application.dto.PhysiologyDtos.PhysiologyEventUpdateRequest;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the PUT note explicit-clearing semantics (N17): an
 * absent/null note key keeps the stored value, a present blank string
 * clears the column to NULL, a non-blank value replaces it — with a
 * mocked repository. The 500-char cap is asserted on the update path too.
 * <p>
 * Also locks the NIX-286 BREEDING → weak-evidence linking hook: deferred to
 * afterCommit inside an active synchronization, run inline (its own
 * REQUIRES_NEW tx) when no synchronization is active.
 */
class PhysiologyEventServiceTest {

    private PhysiologyEventJpaRepository eventRepository;
    private EstrusFeedbackService estrusFeedbackService;
    private PhysiologyEventService service;

    @BeforeEach
    void setUp() {
        eventRepository = mock(PhysiologyEventJpaRepository.class);
        RanchQueryPort ranchQueryPort = mock(RanchQueryPort.class);
        estrusFeedbackService = mock(EstrusFeedbackService.class);
        service = new PhysiologyEventService(
                eventRepository,
                mock(EpidemicDispositionJpaRepository.class),
                ranchQueryPort,
                mock(PhysiologyQueryPort.class),
                estrusFeedbackService);
        when(ranchQueryPort.findLivestockById(5L))
                .thenReturn(Optional.of(new LivestockInfo(5L, 1L, "SL-5", "F", "西门塔尔")));
    }

    /** A MANUAL row carrying a stored note, as the PUT target. */
    private PhysiologyEventJpaEntity manualRow() {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setId(7L);
        entity.setLivestockId(5L);
        entity.setEventType(PhysiologyEventType.ILLNESS);
        entity.setSource(PhysiologySource.MANUAL);
        entity.setOccurredAt(Instant.parse("2026-09-01T16:00:00Z"));
        entity.setNote("old note");
        when(eventRepository.findById(7L)).thenReturn(Optional.of(entity));
        // updateEvent flushes inside its conflict try/catch (m-l), so the
        // update path goes through saveAndFlush.
        when(eventRepository.saveAndFlush(any())).thenAnswer(invocation -> invocation.getArgument(0));
        return entity;
    }

    @Test
    void updateKeepsStoredNoteWhenKeyAbsentOrNull() {
        PhysiologyEventJpaEntity row = manualRow();

        // Key absent (null binding) — note untouched.
        PhysiologyEventResponse kept = service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-02", null), 9L);
        assertThat(row.getNote()).isEqualTo("old note");
        assertThat(kept.note()).isEqualTo("old note");

        // Explicit JSON null binds to the same null — still keeps.
        service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-03", null), 9L);
        assertThat(row.getNote()).isEqualTo("old note");
    }

    @Test
    void updateClearsNoteOnPresentBlankString() {
        PhysiologyEventJpaEntity row = manualRow();

        PhysiologyEventResponse cleared = service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-02", ""), 9L);
        assertThat(row.getNote()).isNull();
        assertThat(cleared.note()).isNull();

        // Whitespace-only trims to empty → clears as well.
        service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-03", "   "), 9L);
        assertThat(row.getNote()).isNull();
    }

    @Test
    void updateReplacesNoteOnNonBlankValue() {
        PhysiologyEventJpaEntity row = manualRow();

        PhysiologyEventResponse replaced = service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-02", "复查正常"), 9L);
        assertThat(row.getNote()).isEqualTo("复查正常");
        assertThat(replaced.note()).isEqualTo("复查正常");
    }

    @Test
    void updateStillRejectsNoteOver500Characters() {
        manualRow();

        assertThatThrownBy(() -> service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-02", "a".repeat(501)), 9L))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.physiology.noteTooLong");
    }

    /**
     * NIX-258 m-l: a concurrent update that slips past the duplicate
     * pre-check and hits uq_physiology_manual_dup on flush must surface as
     * STATE_CONFLICT ("error.physiology.duplicateEvent"), not a 500.
     */
    @Test
    void updateMapsUniqueIndexRaceToStateConflict() {
        manualRow();
        when(eventRepository.saveAndFlush(any()))
                .thenThrow(new DataIntegrityViolationException("uq_physiology_manual_dup"));

        assertThatThrownBy(() -> service.updateEvent(1L, 5L, 7L,
                new PhysiologyEventUpdateRequest("2026-09-02", null), 9L))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.physiology.duplicateEvent")
                .extracting("code")
                .isEqualTo(ErrorCode.STATE_CONFLICT);
    }

    // ── NIX-286 BREEDING → weak-evidence linking hook ───────────

    /** A fresh BREEDING event save echoing the entity back (id stamped). */
    private void breedingSaveSucceeds() {
        when(eventRepository.findByLivestockIdAndEventTypeAndOccurredAtAndSource(
                eq(5L), eq(PhysiologyEventType.BREEDING), any(Instant.class), any()))
                .thenReturn(Optional.empty());
        when(eventRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    }

    /**
     * No active transaction synchronization (the default controller path):
     * the linking runs inline right after the event row exists.
     */
    @Test
    void breedingEventLinksEstrusAlertsInlineWithoutTransactionSync() {
        breedingSaveSucceeds();

        service.createEvent(1L, 5L, new PhysiologyEventRequest("BREEDING", "2026-11-01", null), 9L);

        verify(estrusFeedbackService).linkBreedingDerived(eq(5L), any(Instant.class), eq(9L));
    }

    /**
     * Inside an active synchronization the linking must observe the committed
     * event row — it is registered for afterCommit, not run eagerly.
     */
    @Test
    void breedingEventDefersLinkingUntilAfterCommit() {
        breedingSaveSucceeds();
        TransactionSynchronizationManager.initSynchronization();
        try {
            service.createEvent(1L, 5L, new PhysiologyEventRequest("BREEDING", "2026-11-01", null), 9L);
            verify(estrusFeedbackService, never()).linkBreedingDerived(anyLong(), any(), anyLong());

            for (TransactionSynchronization synchronization :
                    TransactionSynchronizationManager.getSynchronizations()) {
                synchronization.afterCommit();
            }
            verify(estrusFeedbackService).linkBreedingDerived(eq(5L), any(Instant.class), eq(9L));
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    /** Non-BREEDING events never trigger the linking hook. */
    @Test
    void nonBreedingEventDoesNotLinkEstrusAlerts() {
        breedingSaveSucceeds();

        service.createEvent(1L, 5L, new PhysiologyEventRequest("CALVING", "2026-11-01", null), 9L);

        verify(estrusFeedbackService, never()).linkBreedingDerived(anyLong(), any(), anyLong());
    }

    // ── NIX-286 Task 2: record-card isolation from ALERT_CONFIRM audit rows ──

    /** A physiology row of the given type, MANUAL unless it is the audit type. */
    private PhysiologyEventJpaEntity eventRow(long id, PhysiologyEventType type, Instant occurredAt) {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setId(id);
        entity.setLivestockId(5L);
        entity.setEventType(type);
        entity.setSource(type == PhysiologyEventType.ESTRUS_CONFIRM
                ? PhysiologySource.ALERT_CONFIRM
                : PhysiologySource.MANUAL);
        entity.setOccurredAt(occurredAt);
        return entity;
    }

    /**
     * listEvents hides ESTRUS_CONFIRM audit rows (NIX-286 contract v2 §7):
     * even when the repository return carries one (query-exclusion regression
     * or future call path), the merged card list must only show manual
     * milestones — so the frontend `_unknown → illness` degradation never
     * fires on an audit row.
     */
    @Test
    void listEventsExcludesEstrusConfirmAuditRows() {
        when(eventRepository.findVisibleByLivestockIdOrderByOccurredAtDesc(5L))
                .thenReturn(List.of(
                        eventRow(1L, PhysiologyEventType.ESTRUS_CONFIRM,
                                Instant.parse("2026-11-01T09:00:00Z")),
                        eventRow(2L, PhysiologyEventType.ILLNESS,
                                Instant.parse("2026-11-02T09:00:00Z")),
                        eventRow(3L, PhysiologyEventType.RECOVERY,
                                Instant.parse("2026-11-03T09:00:00Z"))));

        PhysiologyEventListResponse response = service.listEvents(1L, 5L);

        assertThat(response.items())
                .extracting(PhysiologyEventResponse::eventType)
                .containsExactlyInAnyOrder("ILLNESS", "RECOVERY");
    }
}
