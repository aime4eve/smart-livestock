package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingEventResponse;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

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
    private DrinkingEventService service;

    @BeforeEach
    void setUp() {
        eventRepository = mock(DrinkingEventJpaRepository.class);
        ranchQueryPort = mock(RanchQueryPort.class);
        service = new DrinkingEventService(eventRepository, ranchQueryPort, mock(DeviceQueryPort.class));
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

    private void verifyWindow(Instant expectedFrom, Instant expectedTo) {
        org.mockito.Mockito.verify(eventRepository)
                .findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                        eq(5L), eq(expectedFrom), eq(expectedTo));
    }
}
