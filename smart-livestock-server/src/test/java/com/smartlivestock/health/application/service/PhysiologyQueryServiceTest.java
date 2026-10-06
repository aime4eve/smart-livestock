package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStage;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStageType;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyWindow;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.EpidemicDispositionJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Mockito unit tests for the {@link PhysiologyQueryService} read-time
 * projections (NIX-258 m-n / m-p): the IN_PROGRESS disposition lane of
 * {@code activeWindows}, per-livestock isolation in the farm batch, and
 * the MANUAL-only source guard on {@code currentStage}.
 */
class PhysiologyQueryServiceTest {

    private static final Instant T1 = Instant.parse("2026-09-02T16:00:00Z");
    private static final Instant T2 = Instant.parse("2026-09-04T16:00:00Z");
    private static final Instant T3 = Instant.parse("2026-09-06T02:30:00Z");

    private PhysiologyEventJpaRepository eventRepository;
    private EpidemicDispositionJpaRepository dispositionRepository;
    private RanchQueryPort ranchQueryPort;
    private PhysiologyQueryService service;

    @BeforeEach
    void setUp() {
        eventRepository = mock(PhysiologyEventJpaRepository.class);
        dispositionRepository = mock(EpidemicDispositionJpaRepository.class);
        ranchQueryPort = mock(RanchQueryPort.class);
        service = new PhysiologyQueryService(eventRepository, dispositionRepository, ranchQueryPort);
        // Same default as health.physiology.lactation-length-days.
        ReflectionTestUtils.setField(service, "lactationLengthDays", 305);
    }

    // ── Helpers ──────────────────────────────────────────────────

    private static PhysiologyEventJpaEntity manualRow(Long livestockId,
            PhysiologyEventType eventType, Instant occurredAt) {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setLivestockId(livestockId);
        entity.setEventType(eventType);
        entity.setSource(PhysiologySource.MANUAL);
        entity.setOccurredAt(occurredAt);
        return entity;
    }

    private static EpidemicDispositionJpaEntity disposition(Long id, Long livestockId,
            EpidemicDispositionStatus status, Instant createdAt) {
        EpidemicDispositionJpaEntity entity = new EpidemicDispositionJpaEntity();
        entity.setId(id);
        entity.setLivestockId(livestockId);
        entity.setStatus(status);
        entity.setCreatedAt(createdAt);
        return entity;
    }

    // ── m-n: IN_PROGRESS disposition projection ──────────────────

    /** An IN_PROGRESS disposition projects as an open ILLNESS window. */
    @Test
    void inProgressDispositionProjectsAsOpenIllnessWindow() {
        when(eventRepository.findByLivestockIdAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
                eq(5L), any(), eq(PhysiologySource.MANUAL), any())).thenReturn(List.of());
        when(dispositionRepository.findByLivestockId(5L))
                .thenReturn(List.of(disposition(99L, 5L, EpidemicDispositionStatus.IN_PROGRESS, T3)));

        List<PhysiologyWindow> windows = service.activeWindows(5L, null, null);

        assertThat(windows).hasSize(1);
        PhysiologyWindow window = windows.get(0);
        assertThat(window.eventType()).isEqualTo(PhysiologyEventType.ILLNESS);
        assertThat(window.occurredAt()).isEqualTo(T3);
        assertThat(window.endedAt()).isNull();
        assertThat(window.sourceType()).isEqualTo("DISPOSITION");
        assertThat(window.refId()).isEqualTo(99L);
    }

    // ── m-n: cross-livestock isolation ───────────────────────────

    /**
     * Two animals each carry one open manual illness: the farm batch must
     * group them per livestock id — A's windows never contain B's and
     * vice versa.
     */
    @Test
    void farmBatchWindowsAreIsolatedPerLivestock() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(
                new LivestockInfo(5L, 1L, "SL-5", "F", "西门塔尔"),
                new LivestockInfo(6L, 1L, "SL-6", "F", "荷斯坦")));
        when(eventRepository.findByLivestockIdInAndEventTypeInAndSourceAndOccurredAtLessThanOrderByOccurredAtAsc(
                anyCollection(), any(), eq(PhysiologySource.MANUAL), any()))
                .thenReturn(List.of(
                        manualRow(5L, PhysiologyEventType.ILLNESS, T1),
                        manualRow(6L, PhysiologyEventType.ILLNESS, T2)));
        when(dispositionRepository.findByLivestockIdIn(anyCollection())).thenReturn(List.of());

        var byLivestock = service.activeWindowsForFarm(1L, null, null);

        assertThat(byLivestock.keySet()).containsExactlyInAnyOrder(5L, 6L);
        assertThat(byLivestock.get(5L))
                .hasSize(1)
                .allSatisfy(w -> {
                    assertThat(w.occurredAt()).isEqualTo(T1);
                    assertThat(w.endedAt()).isNull();
                    assertThat(w.sourceType()).isEqualTo("MANUAL");
                });
        assertThat(byLivestock.get(6L))
                .hasSize(1)
                .allSatisfy(w -> {
                    assertThat(w.occurredAt()).isEqualTo(T2);
                    assertThat(w.endedAt()).isNull();
                    assertThat(w.sourceType()).isEqualTo("MANUAL");
                });
    }

    // ── m-p: MANUAL-only stage guard ─────────────────────────────

    /**
     * Only MANUAL CALVING/DRY_OFF milestones drive the stage: an
     * ALERT_CONFIRM milestone reaching the derivation (a future write
     * path slipping past the repository filter) must be ignored.
     */
    @Test
    void alertConfirmMilestoneDoesNotDriveStage() {
        PhysiologyEventJpaEntity alertConfirmCalving = new PhysiologyEventJpaEntity();
        alertConfirmCalving.setLivestockId(5L);
        alertConfirmCalving.setEventType(PhysiologyEventType.CALVING);
        alertConfirmCalving.setSource(PhysiologySource.ALERT_CONFIRM);
        alertConfirmCalving.setOccurredAt(T1);
        when(eventRepository.findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                eq(5L), any(), any())).thenReturn(Optional.of(alertConfirmCalving));

        assertThat(service.currentStage(5L)).isEmpty();
        // The finder itself is pinned to MANUAL by the service.
        verify(eventRepository).findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                eq(5L), eq(List.of(PhysiologyEventType.CALVING, PhysiologyEventType.DRY_OFF)),
                eq(PhysiologySource.MANUAL));
    }

    /** Counterpart: a recent MANUAL CALVING still yields LACTATING. */
    @Test
    void recentManualCalvingYieldsLactatingStage() {
        when(eventRepository.findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                eq(5L), any(), eq(PhysiologySource.MANUAL)))
                .thenReturn(Optional.of(manualRow(5L, PhysiologyEventType.CALVING, T2)));

        Optional<PhysiologyStage> stage = service.currentStage(5L);

        assertThat(stage).isPresent();
        assertThat(stage.get().type()).isEqualTo(PhysiologyStageType.LACTATING);
        assertThat(stage.get().since()).isEqualTo(T2);
    }
}
