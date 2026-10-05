package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingEventResponse;
import com.smartlivestock.health.domain.model.DrinkingAlgorithmVersion;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests: the statistics counting contract (revised spec §15.3) and the
 * Task 5a list-read window semantics (closed Shanghai date range, default
 * recent 7 days) with a mocked repository.
 */
class DrinkingEventServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    private DrinkingEventJpaRepository eventRepository;
    private RanchQueryPort ranchQueryPort;
    private DeviceQueryPort deviceQueryPort;
    private DrinkingEventService service;

    @BeforeEach
    void setUp() {
        eventRepository = mock(DrinkingEventJpaRepository.class);
        ranchQueryPort = mock(RanchQueryPort.class);
        deviceQueryPort = mock(DeviceQueryPort.class);
        service = new DrinkingEventService(eventRepository, ranchQueryPort, deviceQueryPort);
        service.lowConfidence = 0.5;
        when(ranchQueryPort.findLivestockById(5L))
                .thenReturn(Optional.of(new LivestockInfo(5L, 1L, "SL-5", "F", "西门塔尔")));
    }

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

    // ── Task 5a list read: closed Shanghai day window ───────────

    @Test
    void listEventsFlagsRowsBelowLowConfidenceThreshold() {
        // Server-derived §15.2 marker (M5): 0.400 < 0.5 flags; 0.850 and
        // the human-asserted MANUAL row (confidence 1.0) never flag.
        DrinkingEventJpaEntity low = row("DATAGEN", DrinkingEventLabel.UNLABELED);
        low.setConfidence(new BigDecimal("0.400"));
        DrinkingEventJpaEntity high = row("DATAGEN", DrinkingEventLabel.UNLABELED);
        high.setConfidence(new BigDecimal("0.850"));
        DrinkingEventJpaEntity manual = row(DrinkingEventSources.MANUAL, DrinkingEventLabel.CONFIRMED);
        manual.setConfidence(new BigDecimal("0.100")); // even a low value must not flag MANUAL
        when(eventRepository.findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                eq(5L), any(), any())).thenReturn(List.of(low, high, manual));

        List<DrinkingEventResponse> response = service.listEvents(1L, 5L, null, null);

        assertThat(response).extracting(DrinkingEventResponse::lowConfidence)
                .containsExactly(true, false, false);
    }

    @Test
    void listEventsDefaultsToTheRecentSevenShanghaiDays() {
        DrinkingEventJpaEntity entity = row("DATAGEN", DrinkingEventLabel.UNLABELED);
        entity.setLivestockId(5L);
        entity.setDeviceId(100L);
        entity.setEventStartAt(Instant.now());
        entity.setEventEndAt(Instant.now());
        when(eventRepository.findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                eq(5L), any(), any())).thenReturn(List.of(entity));

        LocalDate today = LocalDate.now(ZONE);
        List<DrinkingEventResponse> response = service.listEvents(1L, 5L, null, null);

        assertThat(response).hasSize(1);
        assertThat(response.get(0).source()).isEqualTo("DATAGEN");
        // Default window: [today-6 00:00, today+1 00:00) Asia/Shanghai.
        verifyWindow(today.minusDays(6).atStartOfDay(ZONE).toInstant(),
                today.plusDays(1).atStartOfDay(ZONE).toInstant());
    }

    @Test
    void listEventsParsesExplicitClosedRange() {
        when(eventRepository.findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                eq(5L), any(), any())).thenReturn(List.of());
        LocalDate from = LocalDate.now(ZONE).minusDays(3);
        LocalDate to = LocalDate.now(ZONE).minusDays(1);

        service.listEvents(1L, 5L, from.toString(), to.toString());

        // Closed date range: to-day is included (window ends at to+1 00:00).
        verifyWindow(from.atStartOfDay(ZONE).toInstant(),
                to.plusDays(1).atStartOfDay(ZONE).toInstant());
    }

    @Test
    void listEventsRejectsBadRangeAndFuture() {
        assertThatThrownBy(() -> service.listEvents(1L, 5L, "2026-13-01", null))
                .isInstanceOf(ApiException.class);
        LocalDate today = LocalDate.now(ZONE);
        assertThatThrownBy(() -> service.listEvents(1L, 5L,
                today.toString(), today.minusDays(1).toString()))
                .isInstanceOf(ApiException.class); // from after to
        assertThatThrownBy(() -> service.listEvents(1L, 5L, null, today.plusDays(1).toString()))
                .isInstanceOf(ApiException.class); // future to-day
        assertThatThrownBy(() -> service.listEvents(1L, 99L, null, null))
                .isInstanceOf(ApiException.class); // livestock of another farm
    }

    // ── PATCH label whitelist (spec §15.2, m-c) ─────────────────

    @Test
    void patchLabelAcceptsOnlyConfirmedAndRejected() {
        DrinkingEventJpaEntity row = row("DATAGEN", DrinkingEventLabel.UNLABELED);
        row.setLivestockId(5L);
        when(eventRepository.findById(7L)).thenReturn(Optional.of(row));
        when(eventRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(service.updateLabel(1L, 5L, 7L, "CONFIRMED").label()).isEqualTo("CONFIRMED");
        assertThat(service.updateLabel(1L, 5L, 7L, "rejected").label()).isEqualTo("REJECTED");
    }

    @Test
    void patchLabelRejectsUnlabeledAndGarbage() {
        DrinkingEventJpaEntity row = row("DATAGEN", DrinkingEventLabel.UNLABELED);
        row.setLivestockId(5L);
        when(eventRepository.findById(7L)).thenReturn(Optional.of(row));

        // UNLABELED is the algorithm default, not a §15.2 PATCH value —
        // the marking loop has no "reset" operation.
        assertThatThrownBy(() -> service.updateLabel(1L, 5L, 7L, "UNLABELED"))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.labelInvalid")
                .extracting("code")
                .isEqualTo(ErrorCode.VALIDATION_ERROR);
        assertThatThrownBy(() -> service.updateLabel(1L, 5L, 7L, "MAYBE"))
                .isInstanceOf(ApiException.class)
                .hasMessage("error.drinking.labelInvalid");
        assertThat(row.getLabel()).isEqualTo(DrinkingEventLabel.UNLABELED); // row untouched
        verify(eventRepository, never()).save(any());
    }

    // ── POST /manual idempotency (m-d) ──────────────────────────

    @Test
    void manualPostReturnsExistingRowOnRepeat() {
        String wallStart = LocalDate.now(ZONE).minusDays(1) + " 09:00";
        Instant startAt = LocalDate.now(ZONE).minusDays(1).atTime(9, 0).atZone(ZONE).toInstant();
        when(deviceQueryPort.findActiveCapsuleBinding(5L))
                .thenReturn(Optional.of(new CapsuleBinding(5L, 100L)));
        DrinkingEventJpaEntity existing = row(DrinkingEventSources.MANUAL, DrinkingEventLabel.CONFIRMED);
        existing.setDeviceId(100L);
        existing.setLivestockId(5L);
        existing.setEventStartAt(startAt);
        existing.setEventEndAt(startAt);
        existing.setAlgorithmVersion(DrinkingAlgorithmVersion.MANUAL);
        when(eventRepository.findByDeviceIdAndEventStartAtAndAlgorithmVersion(
                eq(100L), eq(startAt), eq(DrinkingAlgorithmVersion.MANUAL)))
                .thenReturn(Optional.of(existing));

        DrinkingEventResponse response = service.createManual(1L, 5L, wallStart, "repeat click");

        // Same (device, start, manual) triple → the first row, no insert.
        assertThat(response.source()).isEqualTo(DrinkingEventSources.MANUAL);
        assertThat(response.eventStartAt()).isEqualTo(startAt);
        assertThat(response.lowConfidence()).isFalse();
        verify(eventRepository, never()).save(any());
    }

    private void verifyWindow(Instant expectedFrom, Instant expectedTo) {
        org.mockito.Mockito.verify(eventRepository)
                .findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                        eq(5L), eq(expectedFrom), eq(expectedTo));
    }
}
