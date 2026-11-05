package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineEvaluationReport;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.BaselineLearningCalculator;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.identity.application.TenantZoneResolver;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Task 5 of the individual baseline auto-learning plan (2026-11-03): the
 * read-only A/B evaluation replays the production estrus scoring over ONE
 * event sequence twice (DEFAULT 38.50 vs the learned candidate), merges
 * ≥70 positions into episodes, and never writes anything.
 *
 * <p>The qualifying fixture is hand-computed: 8 groups of night samples
 * 39.2/39.4/39.6 plus a trailing 39.9 spike give a learned baseline of
 * 39.40 (8 qualified days, 24 admitted samples). Under the fixed 500% step
 * increase and 1600 m distance delta the spike scores 70 (delta 1.40) on
 * the DEFAULT side and 64 (delta 0.50) on the learned side, while every
 * quiet sample stays below 70 on the learned side — the exact direction
 * the A/B endpoint exists to surface.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class BaselineEvaluationServiceTest {

    private static final long FARM_ID = 1L;
    private static final long LIVESTOCK_ID = 10L;
    private static final long DEVICE_ID = 51L;
    private static final BigDecimal TEMP_392 = new BigDecimal("39.2");
    private static final BigDecimal TEMP_394 = new BigDecimal("39.4");
    private static final BigDecimal TEMP_396 = new BigDecimal("39.6");
    private static final BigDecimal SPIKE_TEMP = new BigDecimal("39.9");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private TemperatureLogRepository tempLogRepo;
    @Mock private ActivityLogRepository activityLogRepo;
    @Mock private DrinkingEventJpaRepository drinkingEventJpaRepository;
    @Mock private PhysiologyQueryPort physiologyQueryPort;
    @Mock private RanchQueryPort ranchQueryPort;
    private final TenantZoneResolver tenantZoneResolver = org.mockito.Mockito.mock(TenantZoneResolver.class);
    @Mock private com.smartlivestock.shared.common.MessageResolver messageResolver;
    private static final String NOTE_STUB = "note-stub";

    private final BaselineLearningProperties properties = new BaselineLearningProperties();
    private BaselineEvaluationService service;

    @BeforeEach
    void setUp() {
        BaselineLearningInputAssembler assembler = new BaselineLearningInputAssembler(
                properties, drinkingEventJpaRepository, physiologyQueryPort, ranchQueryPort);
        org.mockito.Mockito.doReturn(NOTE_STUB)
                .when(messageResolver)
                .resolve(org.mockito.ArgumentMatchers.eq(BaselineEvaluationService.MECHANISM_NOTE_KEY),
                        org.mockito.ArgumentMatchers.any(),
                        org.mockito.ArgumentMatchers.any());
        service = new BaselineEvaluationService(properties, new BaselineLearningCalculator(),
                assembler, snapshotRepo, tempLogRepo, activityLogRepo,
                new EstrusSeriesReplayer(new EstrusAnalysisService()),
                tenantZoneResolver, messageResolver);

        when(tenantZoneResolver.zoneForFarm(eq(FARM_ID), any())).thenReturn(ZoneOffset.UTC);
        when(physiologyQueryPort.activeWindows(anyLong(), any(), any())).thenReturn(List.of());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(any(), any())).thenReturn(List.of());
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(any(), any(), any()))
                .thenReturn(List.of());
        when(drinkingEventJpaRepository.findByLivestockIdAndEventStartAtLessThanAndEventEndAtGreaterThanEqual(
                anyLong(), any(), any())).thenReturn(List.of());
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID))
                .thenReturn(Optional.of(snapshot("DEFAULT", "38.50")));
    }

    // ── 1. snapshot missing → RESOURCE_NOT_FOUND ────────────────────

    @Test
    void missingSnapshotThrowsResourceNotFound() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.empty());

        ApiException ex = assertThrows(ApiException.class, () -> service.evaluate(LIVESTOCK_ID, null));
        assertEquals(ErrorCode.RESOURCE_NOT_FOUND, ex.getCode());
    }

    // ── 2. A/B comparison on one event sequence ─────────────────────

    @Test
    void evaluationComparesDefaultAndLearnedOnIdenticalInput() {
        Instant anchor = anchor();
        stubWindow(qualifyingTemperatures(anchor), stepActivities(anchor));

        BaselineEvaluationReport report = service.evaluate(LIVESTOCK_ID, null);

        assertEquals(NOTE_STUB, report.note());
        assertEquals(report.evaluatedAt(), report.windowEnd());

        // DEFAULT side: fixed 38.50, no learning evidence attached.
        assertEquals(0, report.defaultSide().baselineTemp().compareTo(DEFAULT_BASELINE));
        assertNull(report.defaultSide().bandLow());
        assertNull(report.defaultSide().bandHigh());
        assertNull(report.defaultSide().admittedSampleCount());
        assertNull(report.defaultSide().qualifiedDays());

        // LEARNED side: hand-computed 39.40 over 8 qualified days / 24 samples.
        assertTrue(report.learnedSide().baselineTemp().compareTo(new BigDecimal("39.30")) >= 0,
                "learned baseline " + report.learnedSide().baselineTemp() + " below expected range");
        assertTrue(report.learnedSide().baselineTemp().compareTo(new BigDecimal("39.45")) <= 0,
                "learned baseline " + report.learnedSide().baselineTemp() + " above expected range");
        assertEquals(24, report.learnedSide().admittedSampleCount());
        assertEquals(8, report.learnedSide().qualifiedDays());
        assertNotNull(report.learnedSide().bandLow());
        assertNotNull(report.learnedSide().bandHigh());

        // One identical event sequence → identical scoring positions.
        assertTrue(report.defaultSide().scoringPoints() > 0);
        assertEquals(report.defaultSide().scoringPoints(), report.learnedSide().scoringPoints());

        // Direction: quiet samples stay below 70 on the learned side, while
        // the DEFAULT side crosses 70 on the 39.6 samples and the spike.
        assertEquals(0, report.learnedSide().highScorePoints());
        assertTrue(report.defaultSide().highScorePoints() > 0);
        assertTrue(report.defaultSide().highScorePoints() > report.learnedSide().highScorePoints());

        // Last scored position = the 39.9 spike: delta 1.40 vs 0.50.
        assertEquals(0, report.defaultSide().lastTempDelta().compareTo(new BigDecimal("1.40")));
        assertEquals(0, report.learnedSide().lastTempDelta().compareTo(new BigDecimal("0.50")));
        assertTrue(report.defaultSide().lastScore() >= 70);
        assertTrue(report.learnedSide().lastScore() < 70);

        // Strictly read-only: no snapshot/log rows are ever written.
        verify(snapshotRepo, never()).save(any());
        verify(tempLogRepo, never()).save(any());
        verify(activityLogRepo, never()).save(any());
    }

    // ── 3. episode merge rule ────────────────────────────────────────

    @Test
    void episodeCountMergesConsecutiveHighScoresWithin24h() {
        Instant first = Instant.parse("2026-11-03T00:00:00Z");

        assertEquals(0, BaselineEvaluationService.episodeCount(List.of()));
        assertEquals(1, BaselineEvaluationService.episodeCount(List.of(first)));
        // 12h gap → same episode.
        assertEquals(1, BaselineEvaluationService.episodeCount(
                List.of(first, first.plus(Duration.ofHours(12)))));
        // 30h gap → a new episode.
        assertEquals(2, BaselineEvaluationService.episodeCount(
                List.of(first, first.plus(Duration.ofHours(30)))));
        // Unsorted input is normalized.
        assertEquals(2, BaselineEvaluationService.episodeCount(
                List.of(first.plus(Duration.ofHours(30)), first)));
    }

    // ── 4. window override clamp 7..14 ───────────────────────────────

    @Test
    void windowOverrideClampsToSevenAndFourteenDays() {
        stubWindow(List.of(), List.of());

        BaselineEvaluationReport report = service.evaluate(LIVESTOCK_ID, 3);
        assertEquals(report.evaluatedAt().minus(Duration.ofDays(7)), report.windowStart());

        ArgumentCaptor<Instant> from = ArgumentCaptor.forClass(Instant.class);
        ArgumentCaptor<Instant> to = ArgumentCaptor.forClass(Instant.class);
        verify(tempLogRepo).findWindowByLivestockId(eq(LIVESTOCK_ID), from.capture(), to.capture());
        assertEquals(report.windowStart(), from.getValue());
        assertEquals(report.evaluatedAt(), to.getValue());

        BaselineEvaluationReport upper = service.evaluate(LIVESTOCK_ID, 20);
        assertEquals(upper.evaluatedAt().minus(Duration.ofDays(14)), upper.windowStart());
    }

    // ── 5. insufficient learned candidate → learnedSide null ────────

    @Test
    void insufficientLearnedCandidateLeavesLearnedSideNull() {
        Instant anchor = anchor();
        // Only 2 qualified days — below min-qualified-days (7).
        List<TemperatureLog> temps = new ArrayList<>();
        Instant day = anchor.minus(Duration.ofDays(2));
        temps.add(temp(TEMP_392, day.plus(Duration.ofHours(22))));
        temps.add(temp(TEMP_394, day.plus(Duration.ofHours(23))));
        temps.add(temp(TEMP_396, day.plus(Duration.ofDays(1))));
        temps.add(temp(TEMP_392, day.plus(Duration.ofDays(1)).plus(Duration.ofHours(22))));
        temps.add(temp(TEMP_394, day.plus(Duration.ofDays(1)).plus(Duration.ofHours(23))));
        stubWindow(temps, stepActivities(anchor));

        BaselineEvaluationReport report = service.evaluate(LIVESTOCK_ID, null);

        assertNull(report.learnedSide());
        // The note is fixed by contract — it never changes shape.
        assertEquals(NOTE_STUB, report.note());
        assertNotNull(report.defaultSide());
        assertEquals(0, report.defaultSide().baselineTemp().compareTo(DEFAULT_BASELINE));
    }

    // ── fixture helpers ──────────────────────────────────────────────

    private HealthSnapshot snapshot(String source, String baselineTemp) {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(LIVESTOCK_ID);
        snapshot.setFarmId(FARM_ID);
        snapshot.setBaselineSource(source);
        snapshot.setBaselineTemp(new BigDecimal(baselineTemp));
        return snapshot;
    }

    private TemperatureLog temp(BigDecimal value, Instant recordedAt) {
        TemperatureLog log = new TemperatureLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setDeviceId(DEVICE_ID);
        log.setTemperature(value);
        log.setRecordedAt(recordedAt);
        log.setSource("MANUAL_IMPORT");
        return log;
    }

    private ActivityLog activity(int steps, int meters, Instant recordedAt) {
        ActivityLog log = new ActivityLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setDeviceId(DEVICE_ID);
        log.setStepCount(steps);
        log.setDistanceMeters(BigDecimal.valueOf(meters));
        // activityIndex stays null on purpose: the learning kernel then
        // admits via the night fallback, independent of these rows.
        log.setRecordedAt(recordedAt);
        log.setSource("MANUAL_IMPORT");
        return log;
    }

    /**
     * A UTC midnight at least one hour in the past. Every fixture instant
     * derives from it, so all samples sit strictly inside the evaluation
     * window regardless of the wall clock the suite runs at.
     */
    private static Instant anchor() {
        return Instant.now().minus(Duration.ofHours(1)).truncatedTo(ChronoUnit.DAYS);
    }

    /**
     * 8 groups of night samples 39.2/39.4/39.6 (groups 0-6 close with a
     * next-midnight 39.6) plus the trailing 39.9 spike at 23:30 — 8
     * qualified days, 24 admitted samples, learned baseline 39.40.
     */
    private List<TemperatureLog> qualifyingTemperatures(Instant anchor) {
        List<TemperatureLog> temps = new ArrayList<>();
        for (int g = 0; g <= 7; g++) {
            Instant day = anchor.minus(Duration.ofDays(8L - g));
            temps.add(temp(TEMP_392, day.plus(Duration.ofHours(22))));
            temps.add(temp(TEMP_394, day.plus(Duration.ofHours(23))));
            if (g < 7) {
                temps.add(temp(TEMP_396, day.plus(Duration.ofDays(1))));
            }
        }
        temps.add(temp(SPIKE_TEMP, anchor.minus(Duration.ofMinutes(30))));
        return temps;
    }

    /**
     * 7 activity rows on the oldest fixture day, 08:00-14:00 UTC — strictly
     * before the first temperature, so every scoring position sees all 7
     * and the newest-3-vs-rest split is constant: steps 400×3 vs 50×4
     * (→ 500%) and distances 600×3 vs 50×4 (→ 1600 m).
     */
    private List<ActivityLog> stepActivities(Instant anchor) {
        List<ActivityLog> acts = new ArrayList<>();
        Instant day = anchor.minus(Duration.ofDays(8));
        for (int h = 0; h < 7; h++) {
            acts.add(activity(h < 4 ? 50 : 400, h < 4 ? 50 : 600,
                    day.plus(Duration.ofHours(8L + h))));
        }
        return acts;
    }

    private void stubWindow(List<TemperatureLog> temps, List<ActivityLog> acts) {
        when(tempLogRepo.findWindowByLivestockId(eq(LIVESTOCK_ID), any(), any())).thenReturn(temps);
        when(activityLogRepo.findWindowByLivestockId(eq(LIVESTOCK_ID), any(), any())).thenReturn(acts);
    }
}
