package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingPeerComparisonResponse;
import com.smartlivestock.health.application.dto.DrinkingDtos.DrinkingSummaryResponse;
import com.smartlivestock.health.application.service.DrinkingEventDetectionService.ExclusionWindow;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStage;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStageType;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.never;

/**
 * Pure unit tests for the Task 5a aggregation service (mocked repositories
 * and collaborators): the three counting layers (daily with REJECTED
 * excluded and candidates counted only after confirmation, weekly direct
 * sum, 30-day baseline over sample days), the sample-day rule (min points,
 * fever coverage strictly below 50%), and the Shanghai cow-day boundary
 * (UTC 16:00 = local midnight). Wall clocks in fixtures are Asia/Shanghai.
 */
class DrinkingSummaryServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final long FARM_ID = 1L;
    private static final long TARGET_ID = 5L;

    private DrinkingEventJpaRepository eventRepository;
    private TemperatureLogJpaRepository temperatureLogRepository;
    private DrinkingEventDetectionService detectionService;
    private DrinkingPeerAccessGuard peerAccessGuard;
    private RanchQueryPort ranchQueryPort;
    private PhysiologyQueryPort physiologyQueryPort;
    private DrinkingSummaryService service;

    private LocalDate today;

    @BeforeEach
    void setUp() {
        eventRepository = mock(DrinkingEventJpaRepository.class);
        temperatureLogRepository = mock(TemperatureLogJpaRepository.class);
        detectionService = mock(DrinkingEventDetectionService.class);
        peerAccessGuard = mock(DrinkingPeerAccessGuard.class);
        ranchQueryPort = mock(RanchQueryPort.class);
        physiologyQueryPort = mock(PhysiologyQueryPort.class);
        service = new DrinkingSummaryService(eventRepository, temperatureLogRepository,
                detectionService, peerAccessGuard, ranchQueryPort, physiologyQueryPort);
        service.sampleDayMinPoints = 24;

        today = LocalDate.now(ZONE);
        when(ranchQueryPort.findLivestockById(TARGET_ID))
                .thenReturn(Optional.of(livestock(TARGET_ID, "西门塔尔")));
        when(detectionService.feverWindowsForLivestock(eq(TARGET_ID), any(), any()))
                .thenReturn(List.of());
    }

    // ── Fixtures ────────────────────────────────────────────────

    private static LivestockInfo livestock(long id, String breed) {
        return new LivestockInfo(id, FARM_ID, "SL-" + id, "F", breed);
    }

    private static Instant at(LocalDate day, String wallClock) {
        return day.atTime(java.time.LocalTime.parse(wallClock)).atZone(ZONE).toInstant();
    }

    private static ExclusionWindow feverWindow(LocalDate day, String fromClock, String toClock) {
        return new ExclusionWindow(at(day, fromClock), at(day, toClock));
    }

    private static DrinkingEventJpaEntity row(LocalDate day, String startClock, String endClock,
                                              String source, DrinkingEventLabel label) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setDeviceId(100L);
        entity.setLivestockId(TARGET_ID);
        entity.setEventStartAt(at(day, startClock));
        entity.setEventEndAt(at(day, endClock));
        entity.setTempDrop(new BigDecimal("2.20"));
        entity.setMinTemp(new BigDecimal("36.80"));
        entity.setSource(source);
        entity.setLabel(label);
        entity.setConfidence(new BigDecimal("0.850"));
        return entity;
    }

    private static DrinkingEventJpaEntity counted(LocalDate day, String startClock, String endClock) {
        return row(day, startClock, endClock, "DATAGEN", DrinkingEventLabel.UNLABELED);
    }

    /**
     * Points per (livestock, day): listed days get their value, unlisted
     * days get {@code unlistedDefault} — 0 for "no data", 48 for
     * "well-observed except the listed exceptions".
     */
    private void stubPointCounts(long unlistedDefault, Map<Long, Map<LocalDate, Long>> countsByLivestock) {
        when(temperatureLogRepository.countByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThan(
                anyLong(), any(), any())).thenAnswer(invocation -> {
            Long livestockId = invocation.getArgument(0);
            Instant from = invocation.getArgument(1);
            return countsByLivestock
                    .getOrDefault(livestockId, Map.of())
                    .getOrDefault(LocalDate.ofInstant(from, ZONE), unlistedDefault);
        });
    }

    private void stubEvents(List<DrinkingEventJpaEntity> rows) {
        when(eventRepository.findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                eq(TARGET_ID), any(), any())).thenReturn(rows);
    }

    // ── 1. daily: direct count with §15.3 filtering ─────────────

    @Test
    void dailyCountsIsCountedRowsOnlyAndPinsLastDrinkEndAt() {
        List<DrinkingEventJpaEntity> rows = new ArrayList<>(List.of(
                counted(today, "09:00", "09:10"),
                row(today, "10:00", "10:10", "DATAGEN", DrinkingEventLabel.REJECTED),
                row(today, "11:00", "11:05", DrinkingEventSources.ALGORITHM_CANDIDATE,
                        DrinkingEventLabel.UNLABELED),
                row(today, "12:00", "12:05", DrinkingEventSources.ALGORITHM_CANDIDATE,
                        DrinkingEventLabel.CONFIRMED),   // promoted candidate counts
                row(today, "13:00", "13:05", DrinkingEventSources.MANUAL,
                        DrinkingEventLabel.CONFIRMED),   // manual back-fill counts
                counted(today.minusDays(1), "23:00", "23:10"))); // other day, not in daily
        stubEvents(rows);

        DrinkingSummaryResponse response = service.summary(FARM_ID, TARGET_ID, today.toString(), 1);

        assertThat(response.daily().count()).isEqualTo(3);
        assertThat(response.daily().events()).hasSize(3);
        assertThat(response.daily().events().get(0).startAt()).isEqualTo(at(today, "09:00"));
        assertThat(response.daily().events().get(2).source()).isEqualTo(DrinkingEventSources.MANUAL);
        assertThat(response.daily().lastDrinkEndAt()).isEqualTo(at(today, "13:05"));
        // days=1 answers the daily layer only — no weekly/baseline/bars.
        assertThat(response.weekly()).isNull();
        assertThat(response.rolling30dBaseline()).isNull();
        assertThat(response.dayCounts()).isNull();
        assertThat(response.date()).isEqualTo(today);
        assertThat(response.days()).isEqualTo(1);
    }

    // ── 2. weekly: direct sum, fever days stay (F4 layer 1) ─────

    @Test
    void weeklyDirectlySumsSevenDaysIncludingFeverLows() {
        int[] perDay = {8, 7, 9, 6, 3, 8, 7}; // prototype numbers: fever Friday is a low 3
        List<DrinkingEventJpaEntity> rows = new ArrayList<>();
        for (int offset = 6; offset >= 0; offset--) {
            LocalDate day = today.minusDays(offset);
            for (int i = 0; i < perDay[6 - offset]; i++) {
                rows.add(counted(day, String.format("%02d:00", 8 + i), String.format("%02d:10", 8 + i)));
            }
        }
        stubEvents(rows);
        // Fever on the low day (10:20–16:40 ≈ 26% coverage) — bar marked,
        // but the weekly sum still counts the day's 3 events.
        LocalDate feverDay = today.minusDays(2);
        when(detectionService.feverWindowsForLivestock(eq(TARGET_ID), any(), any()))
                .thenReturn(List.of(feverWindow(feverDay, "10:20", "16:40")));

        DrinkingSummaryResponse response = service.summary(FARM_ID, TARGET_ID, today.toString(), 7);

        assertThat(response.weekly().count()).isEqualTo(48);
        assertThat(response.weekly().avgPerDay()).isEqualByComparingTo(new BigDecimal("6.86"));
        assertThat(response.dayCounts()).hasSize(7);
        assertThat(response.dayCounts().get(0).date()).isEqualTo(today.minusDays(6));
        assertThat(response.dayCounts().get(6).date()).isEqualTo(today);
        assertThat(response.dayCounts().stream()
                .filter(bar -> bar.date().equals(feverDay))
                .findFirst().orElseThrow().feverCoveredPercent())
                .isCloseTo(BigDecimal.valueOf(26.4), within(BigDecimal.valueOf(0.1)));
        assertThat(response.dayCounts().stream()
                .filter(bar -> !bar.date().equals(feverDay))
                .allMatch(bar -> bar.feverCoveredPercent().compareTo(BigDecimal.ZERO) == 0))
                .isTrue();
        assertThat(response.rolling30dBaseline()).isNull();
    }

    // ── 3. baseline: sample days only (F4 layer 2) ──────────────

    @Test
    void rollingBaselineExcludesFeverCoveredAndLowPointDays() {
        // 30 days × 8 events; fever day carries 3 (excluded from baseline),
        // low-point day carries 8 but has only 10 temperature points.
        LocalDate feverDay = today.minusDays(10);
        LocalDate lowPointDay = today.minusDays(20);
        List<DrinkingEventJpaEntity> rows = new ArrayList<>();
        for (int offset = 29; offset >= 0; offset--) {
            LocalDate day = today.minusDays(offset);
            int events = day.equals(feverDay) ? 3 : 8;
            for (int i = 0; i < events; i++) {
                rows.add(counted(day, String.format("%02d:00", 8 + i), String.format("%02d:10", 8 + i)));
            }
        }
        stubEvents(rows);
        // 14.4h = 60% coverage on the fever day.
        when(detectionService.feverWindowsForLivestock(eq(TARGET_ID), any(), any()))
                .thenReturn(List.of(feverWindow(feverDay, "06:00", "20:24")));
        stubPointCounts(48, Map.of(TARGET_ID, Map.of(lowPointDay, 10L)));

        DrinkingSummaryResponse response = service.summary(FARM_ID, TARGET_ID, today.toString(), 30);

        // 28 sample days × 8 events (fever day and low-point day dropped).
        assertThat(response.rolling30dBaseline().sampleDays()).isEqualTo(28);
        assertThat(response.rolling30dBaseline().avgPerDay()).isEqualByComparingTo(new BigDecimal("8.00"));
        assertThat(response.dayCounts()).hasSize(30);
        assertThat(response.dayCounts().stream()
                .filter(bar -> bar.date().equals(feverDay))
                .findFirst().orElseThrow().feverCoveredPercent())
                .isCloseTo(BigDecimal.valueOf(60.0), within(BigDecimal.valueOf(0.1)));
        assertThat(response.weekly()).isNull();
    }

    @Test
    void baselineWithoutSampleDaysReturnsNullAverage() {
        stubEvents(List.of(counted(today, "09:00", "09:10")));
        stubPointCounts(0, Map.of(TARGET_ID, Map.of())); // zero points everywhere

        DrinkingSummaryResponse response = service.summary(FARM_ID, TARGET_ID, today.toString(), 30);

        assertThat(response.rolling30dBaseline().sampleDays()).isZero();
        assertThat(response.rolling30dBaseline().avgPerDay()).isNull();
    }

    // ── 4. sample-day rule: points and the strict 50% line ──────

    @Test
    void sampleDayRulePinsBoundaries() {
        // Enough points, no fever → sample day.
        assertThat(DrinkingSummaryService.isSampleDay(24, 0.0, 24)).isTrue();
        // Below the point floor → not a sample day (even without fever).
        assertThat(DrinkingSummaryService.isSampleDay(23, 0.0, 24)).isFalse();
        // Fever 60% → excluded; exactly 50% → excluded (rule is strictly <50);
        // just under the line → included.
        assertThat(DrinkingSummaryService.isSampleDay(48, 60.0, 24)).isFalse();
        assertThat(DrinkingSummaryService.isSampleDay(48, 50.0, 24)).isFalse();
        assertThat(DrinkingSummaryService.isSampleDay(48, 49.9, 24)).isTrue();
    }

    @Test
    void feverCoverageMergesOverlapsAndClampsAtDayBounds() {
        LocalDate day = LocalDate.of(2026, 6, 10);
        // Two overlapping windows 08:00–12:00 and 10:00–14:00 merge into
        // 08:00–14:00 = 360 min = 25% (not 50% double-counted).
        List<ExclusionWindow> windows = List.of(
                feverWindow(day, "08:00", "12:00"),
                feverWindow(day, "10:00", "14:00"));
        assertThat(DrinkingSummaryService.feverCoveredPercent(windows, day, ZONE))
                .isCloseTo(25.0, within(1e-9));
        // Window spilling across midnight clamps at the day boundary:
        // 20:00 → next 04:00 intersects this day 20:00–24:00 = 240 min.
        List<ExclusionWindow> spilling = List.of(new ExclusionWindow(
                at(day, "20:00"), at(day.plusDays(1), "04:00")));
        assertThat(DrinkingSummaryService.feverCoveredPercent(spilling, day, ZONE))
                .isCloseTo(100.0 * 240 / 1440, within(1e-9));
        // Open-ended window covers the whole day.
        List<ExclusionWindow> open = List.of(new ExclusionWindow(at(day.minusDays(1), "12:00"), null));
        assertThat(DrinkingSummaryService.feverCoveredPercent(open, day, ZONE))
                .isCloseTo(100.0, within(1e-9));
    }

    // ── 5. cow-day boundary: UTC 16:00 is local midnight (F5) ───

    @Test
    void cowDayBoundarySplitsAtUtcSixteen() {
        DrinkingEventJpaEntity beforeMidnight = new DrinkingEventJpaEntity();
        beforeMidnight.setEventStartAt(Instant.parse("2026-06-10T15:59:00Z")); // SH 23:59
        beforeMidnight.setEventEndAt(Instant.parse("2026-06-10T16:01:00Z"));
        beforeMidnight.setSource("DATAGEN");
        beforeMidnight.setLabel(DrinkingEventLabel.UNLABELED);
        DrinkingEventJpaEntity afterMidnight = new DrinkingEventJpaEntity();
        afterMidnight.setEventStartAt(Instant.parse("2026-06-10T16:00:00Z")); // SH next 00:00
        afterMidnight.setEventEndAt(Instant.parse("2026-06-10T16:05:00Z"));
        afterMidnight.setSource("DATAGEN");
        afterMidnight.setLabel(DrinkingEventLabel.UNLABELED);

        Map<LocalDate, Integer> counts = DrinkingSummaryService.countedPerDay(
                List.of(beforeMidnight, afterMidnight), ZONE);

        assertThat(counts).containsEntry(LocalDate.of(2026, 6, 10), 1);
        assertThat(counts).containsEntry(LocalDate.of(2026, 6, 11), 1);
    }

    // ── 6. request validation ───────────────────────────────────

    @Test
    void summaryValidatesDaysAndDate() {
        assertThatThrownBy(() -> service.summary(FARM_ID, TARGET_ID, null, 5))
                .isInstanceOfSatisfying(ApiException.class, e ->
                        assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        assertThatThrownBy(() -> service.summary(FARM_ID, TARGET_ID, "not-a-date", 7))
                .isInstanceOfSatisfying(ApiException.class, e ->
                        assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
        assertThatThrownBy(() -> service.summary(FARM_ID, TARGET_ID, today.plusDays(1).toString(), 7))
                .isInstanceOfSatisfying(ApiException.class, e ->
                        assertThat(e.getCode()).isEqualTo(ErrorCode.VALIDATION_ERROR));
    }

    @Test
    void summaryRejectsLivestockOfAnotherFarm() {
        when(ranchQueryPort.findLivestockById(99L)).thenReturn(Optional.of(
                new LivestockInfo(99L, 2L, "SL-99", "F", "西门塔尔")));
        assertThatThrownBy(() -> service.summary(FARM_ID, 99L, null, 7))
                .isInstanceOf(ApiException.class);
    }

    // ── 7. peer comparison (endpoint 3) ─────────────────────────

    @Test
    void peerComparisonChecksPremiumBeforeAnythingElse() {
        org.mockito.Mockito.doThrow(new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.drinking.premiumRequired"))
                .when(peerAccessGuard).requirePeerComparison();

        assertThatThrownBy(() -> service.peerComparison(FARM_ID, TARGET_ID))
                .isInstanceOf(ApiException.class);
        // The tier gate fires before any data access — no existence oracle.
        verify(ranchQueryPort, never()).findLivestockById(anyLong());
    }

    @Test
    void peerComparisonWithoutOtherGroupMembersDegradesToInsufficientPeers() {
        when(ranchQueryPort.findAllByFarmId(FARM_ID)).thenReturn(List.of(livestock(TARGET_ID, "西门塔尔")));
        when(physiologyQueryPort.currentStage(anyLong())).thenReturn(Optional.empty());
        when(detectionService.feverWindowsByFarm(eq(FARM_ID), any(), any())).thenReturn(Map.of());

        DrinkingPeerComparisonResponse response = service.peerComparison(FARM_ID, TARGET_ID);

        assertThat(response.peerAvgPerDay()).isNull();
        assertThat(response.reason()).isEqualTo("INSUFFICIENT_PEERS");
        assertThat(response.groupBreed()).isEqualTo("西门塔尔");
        assertThat(response.groupStage()).isNull();
        assertThat(response.minSampleDays()).isEqualTo(5);
    }

    @Test
    void peerComparisonAveragesGroupAndKeepsTargetInTheDenominator() {
        // Same breed+stage peers 6 and 7; livestock 8 differs in breed and 9
        // in stage — both filtered out of the group.
        when(ranchQueryPort.findAllByFarmId(FARM_ID)).thenReturn(List.of(
                livestock(TARGET_ID, "西门塔尔"),
                livestock(6L, "西门塔尔"),
                livestock(7L, "西门塔尔"),
                livestock(8L, "荷斯坦"),
                livestock(9L, "西门塔尔")));
        when(physiologyQueryPort.currentStage(eq(TARGET_ID)))
                .thenReturn(Optional.of(new PhysiologyStage(PhysiologyStageType.LACTATING,
                        at(today.minusDays(128), "00:00"))));
        when(physiologyQueryPort.currentStage(eq(6L)))
                .thenReturn(Optional.of(new PhysiologyStage(PhysiologyStageType.LACTATING,
                        at(today.minusDays(10), "00:00"))));
        when(physiologyQueryPort.currentStage(eq(7L)))
                .thenReturn(Optional.of(new PhysiologyStage(PhysiologyStageType.LACTATING,
                        at(today.minusDays(5), "00:00"))));
        when(physiologyQueryPort.currentStage(eq(8L))).thenReturn(Optional.empty());
        when(physiologyQueryPort.currentStage(eq(9L)))
                .thenReturn(Optional.of(new PhysiologyStage(PhysiologyStageType.DRY,
                        at(today.minusDays(30), "00:00"))));
        when(detectionService.feverWindowsByFarm(eq(FARM_ID), any(), any())).thenReturn(Map.of());

        // Peers: 30 sample days; target: only 3 sample days (device fitted
        // late) — it still stays in the denominator per the spec.
        stubPointCounts(0, Map.of(
                TARGET_ID, pointsOnDays(3),
                6L, pointsOnDays(30),
                7L, pointsOnDays(30)));
        stubEventsPerLivestock(Map.of(
                TARGET_ID, eventsOnDays(3, 8),   // 24 counted on its sample days
                6L, eventsOnDays(30, 7),         // 210
                7L, eventsOnDays(30, 6)));       // 180

        DrinkingPeerComparisonResponse response = service.peerComparison(FARM_ID, TARGET_ID);

        assertThat(response.reason()).isNull();
        assertThat(response.groupBreed()).isEqualTo("西门塔尔");
        assertThat(response.groupStage()).isEqualTo("LACTATING");
        assertThat(response.peerCount()).isEqualTo(3);
        assertThat(response.sampleDaysTotal()).isEqualTo(63); // 30 + 30 + target's 3
        assertThat(response.peerAvgPerDay()).isEqualByComparingTo(new BigDecimal("6.57")); // 414/63
    }

    @Test
    void peerComparisonDegradesWhenNoPeerReachesMinSampleDays() {
        when(ranchQueryPort.findAllByFarmId(FARM_ID)).thenReturn(List.of(
                livestock(TARGET_ID, "西门塔尔"), livestock(6L, "西门塔尔")));
        when(physiologyQueryPort.currentStage(anyLong())).thenReturn(Optional.empty());
        when(detectionService.feverWindowsByFarm(eq(FARM_ID), any(), any())).thenReturn(Map.of());
        // Peer 6 has temperature data on only 4 days → below MIN_SAMPLE_DAYS=5.
        stubPointCounts(0, Map.of(TARGET_ID, pointsOnDays(30), 6L, pointsOnDays(4)));
        stubEventsPerLivestock(Map.of(
                TARGET_ID, eventsOnDays(30, 8), 6L, eventsOnDays(4, 8)));

        DrinkingPeerComparisonResponse response = service.peerComparison(FARM_ID, TARGET_ID);

        assertThat(response.peerAvgPerDay()).isNull();
        assertThat(response.reason()).isEqualTo("INSUFFICIENT_PEERS");
        assertThat(response.peerCount()).isZero();
        assertThat(response.sampleDaysTotal()).isZero();
    }

    // ── Peer fixtures ───────────────────────────────────────────

    /** Point-count map: {@code n} days (ending today) with 48 points, rest absent. */
    private static Map<LocalDate, Long> pointsOnDays(int n) {
        Map<LocalDate, Long> days = new TreeMap<>();
        for (int offset = n - 1; offset >= 0; offset--) {
            days.put(LocalDate.now(ZONE).minusDays(offset), 48L);
        }
        return days;
    }

    private static List<DrinkingEventJpaEntity> eventsOnDays(int n, int perDay) {
        List<DrinkingEventJpaEntity> rows = new ArrayList<>();
        for (int offset = n - 1; offset >= 0; offset--) {
            LocalDate day = LocalDate.now(ZONE).minusDays(offset);
            for (int i = 0; i < perDay; i++) {
                rows.add(counted(day, String.format("%02d:00", 8 + i), String.format("%02d:10", 8 + i)));
            }
        }
        return rows;
    }

    private void stubEventsPerLivestock(Map<Long, List<DrinkingEventJpaEntity>> rowsByLivestock) {
        when(eventRepository.findByLivestockIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThanOrderByEventStartAtDesc(
                anyLong(), any(), any())).thenAnswer(invocation ->
                rowsByLivestock.getOrDefault(invocation.getArgument(0), List.of()));
    }
}
