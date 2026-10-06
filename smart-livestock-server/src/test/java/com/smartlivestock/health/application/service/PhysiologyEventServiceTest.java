package com.smartlivestock.health.application.service;

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

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the PUT note explicit-clearing semantics (N17): an
 * absent/null note key keeps the stored value, a present blank string
 * clears the column to NULL, a non-blank value replaces it — with a
 * mocked repository. The 500-char cap is asserted on the update path too.
 */
class PhysiologyEventServiceTest {

    private PhysiologyEventJpaRepository eventRepository;
    private PhysiologyEventService service;

    @BeforeEach
    void setUp() {
        eventRepository = mock(PhysiologyEventJpaRepository.class);
        RanchQueryPort ranchQueryPort = mock(RanchQueryPort.class);
        service = new PhysiologyEventService(
                eventRepository,
                mock(EpidemicDispositionJpaRepository.class),
                ranchQueryPort,
                mock(PhysiologyQueryPort.class));
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
}
