package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.EstrusScore;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.repository.*;
import com.smartlivestock.health.domain.service.*;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.health.infrastructure.config.EstrusScoringProperties;
import com.smartlivestock.health.infrastructure.persistence.entity.ActivityLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.ActivityLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.repository.ActivityLogRepositoryImpl;
import com.smartlivestock.identity.application.TenantZoneResolver;
import com.smartlivestock.iot.domain.model.DeviceType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * NIX-380 Task 2: the mode-gated triggerEstrusScoring wiring.
 *
 * <p>LEGACY mode must reproduce the pre-normalization row byte-for-byte
 * (feature columns carry the old increase-percent / absolute-delta values and
 * the window read is never touched). NORMALIZED mode compares the current
 * window against same-phase baseline windows taken at exact 24h multiples
 * before the anchor, writes LEGACY-shaped columns — increase percent
 * {@code (ratio − 1) × 100} and absolute meter delta currentMean −
 * baselineMedian — computed from the cross-event-window levels, and enforces
 * the fail-silent guards. The scoring kernel itself is the real
 * {@link EstrusAnalysisService} (locked by its own unit tests).</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class EstrusNormalizedScoringTest {

    private static final long FARM_ID = 1L;
    private static final long LIVESTOCK_ID = 10L;
    private static final long DEVICE_ID = 51L;
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");
    /** Anchor = newest temperature sample instant; focal point of all windows. */
    private static final Instant ANCHOR = Instant.parse("2026-06-04T12:00:00Z");
    /** anchor − (3 baseline windows × 24h offset + 6h current window) — the read's lower bound. */
    private static final Instant SPAN_START = ANCHOR.minus(Duration.ofHours(78));
    private static final Instant CURRENT_START = ANCHOR.minus(Duration.ofHours(6));

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private TemperatureLogRepository tempLogRepo;
    @Mock private RumenMotilityLogRepository motilityLogRepo;
    @Mock private ActivityLogRepository activityLogRepo;
    @Mock private EstrusScoreRepository estrusScoreRepo;
    @Mock private ContactTraceRepository contactTraceRepo;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private HealthSubscriptionPort subscriptionPort;
    @Mock private FeverAnalysisService feverService;
    @Mock private DigestiveAnalysisService digestiveService;
    @Mock private EpidemicAnalysisService epidemicService;
    @Mock private HealthAnomalyService healthAnomalyService;
    @Mock private HealthAlertBridgeService healthAlertBridgeService;
    @Mock private com.smartlivestock.shared.common.MessageResolver messageResolver;
    @Mock private com.smartlivestock.ranch.application.signal.SignalRevisionService signalRevisionService;

    private final TenantZoneResolver tenantZoneResolver = mock(TenantZoneResolver.class);

    private EstrusScoringProperties estrusProps;
    private HealthApplicationService service;

    @BeforeEach
    void setUp() {
        estrusProps = new EstrusScoringProperties(); // defaults: mode NORMALIZED, 6h/3×24h windows
        service = new HealthApplicationService(
                tenantZoneResolver,
                snapshotRepo, tempLogRepo, motilityLogRepo, activityLogRepo,
                estrusScoreRepo, contactTraceRepo,
                ranchQueryPort, ranchCommandPort,
                mock(com.smartlivestock.ranch.domain.port.IoTQueryPort.class),
                subscriptionPort,
                healthAnomalyService,
                healthAlertBridgeService,
                signalRevisionService,
                feverService, digestiveService, new EstrusAnalysisService(), epidemicService,
                messageResolver,
                mock(ContactAnalysisService.class),
                new BaselineLearningProperties(),
                estrusProps);

        when(tenantZoneResolver.zoneForFarm(anyLong(), any())).thenReturn(java.time.ZoneOffset.UTC);
        doNothing().when(snapshotRepo).ensureSnapshotExists(anyLong(), anyLong());
    }

    // ── helpers ─────────────────────────────────────────────────

    private TemperatureLog tempAt(Instant at, String temperature) {
        TemperatureLog log = new TemperatureLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setDeviceId(DEVICE_ID);
        log.setTemperature(new BigDecimal(temperature));
        log.setBaselineTemp(DEFAULT_BASELINE);
        log.setRecordedAt(at);
        return log;
    }

    private ActivityLog activityAt(Instant at, String activityIndex, Integer stepCount, String distance) {
        ActivityLog log = new ActivityLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setDeviceId(DEVICE_ID);
        log.setActivityIndex(activityIndex == null ? null : new BigDecimal(activityIndex));
        log.setStepCount(stepCount);
        log.setDistanceMeters(distance == null ? null : new BigDecimal(distance));
        log.setRecordedAt(at);
        return log;
    }

    /** 30-minute cadence samples across the half-open window [start, end) — 12 per 6h window. */
    private List<ActivityLog> series(Instant start, Instant end,
                                     String activityIndex, Integer stepCount, String distance) {
        List<ActivityLog> logs = new ArrayList<>();
        for (Instant t = start; t.isBefore(end); t = t.plus(Duration.ofMinutes(30))) {
            logs.add(activityAt(t, activityIndex, stepCount, distance));
        }
        return logs;
    }

    /** The 3 baseline windows (k=3,2,1) with the given channel values. */
    private List<ActivityLog> baselineWindows(String activityIndex, Integer stepCount, String distance) {
        List<ActivityLog> logs = new ArrayList<>();
        logs.addAll(series(SPAN_START, SPAN_START.plus(Duration.ofHours(6)),
                activityIndex, stepCount, distance)); // baseline k=3
        logs.addAll(series(SPAN_START.plus(Duration.ofHours(24)), SPAN_START.plus(Duration.ofHours(30)),
                activityIndex, stepCount, distance)); // baseline k=2
        logs.addAll(series(SPAN_START.plus(Duration.ofHours(48)), SPAN_START.plus(Duration.ofHours(54)),
                activityIndex, stepCount, distance)); // baseline k=1
        return logs;
    }

    /** Full span: current window + all 3 baseline windows (same values everywhere by default). */
    private List<ActivityLog> spanSeries(String activityIndex, Integer stepCount, String distance) {
        List<ActivityLog> logs = baselineWindows(activityIndex, stepCount, distance);
        logs.addAll(series(CURRENT_START, ANCHOR, activityIndex, stepCount, distance)); // current
        return logs;
    }

    private HealthSnapshot defaultSnapshot() {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(LIVESTOCK_ID);
        snapshot.setFarmId(FARM_ID);
        snapshot.setBaselineSource("DEFAULT");
        snapshot.setBaselineTemp(DEFAULT_BASELINE);
        return snapshot;
    }

    /** Stubs the temperature side of the normalized chain: anchor 39.05 + an older sample. */
    private void stubTemperatureChain() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(defaultSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 1))
                .thenReturn(List.of(tempAt(ANCHOR, "39.05")));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 7))
                .thenReturn(List.of(
                        tempAt(ANCHOR, "39.05"),
                        tempAt(ANCHOR.minus(Duration.ofMinutes(30)), "38.90")));
    }

    private void stubWindowLogs(List<ActivityLog> logs) {
        when(activityLogRepo.findWindowByLivestockId(eq(LIVESTOCK_ID), any(), any(), anyInt()))
                .thenReturn(logs);
    }

    /** CAPSULE telemetry carrying the anchor temperature — drives the full
     *  processTelemetry → refreshSnapshot → triggerEstrusScoring chain. */
    private void processAnchorTelemetry() {
        service.processTelemetry(DEVICE_ID, LIVESTOCK_ID, FARM_ID, DeviceType.CAPSULE,
                Map.of("temperature", 39.05), ANCHOR, "AGENTIC_PLATFORM");
    }

    private EstrusScore captureSavedScore() {
        ArgumentCaptor<EstrusScore> captor = ArgumentCaptor.forClass(EstrusScore.class);
        verify(estrusScoreRepo).save(captor.capture());
        return captor.getValue();
    }

    private static void assertBigDecimalEquals(String expected, BigDecimal actual) {
        assertNotNull(actual);
        assertEquals(0, new BigDecimal(expected).compareTo(actual),
                "expected " + expected + " but was " + actual);
    }

    // ── 1. LEGACY regression: pre-normalization output unchanged ──

    @Test
    void legacyMode_producesPreNormalizationRow_unchanged() {
        estrusProps.setMode("LEGACY");
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(defaultSnapshot()));
        // Same data shape as EstrusBaselineConsumptionTest: 2 temps + 3 activities.
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 7)).thenReturn(List.of(
                tempAt(ANCHOR, "39.90"), tempAt(ANCHOR.minus(Duration.ofMinutes(30)), "38.90")));
        when(activityLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 7)).thenReturn(List.of(
                activityAt(ANCHOR, "50.0", 1000, "100.0"),
                activityAt(ANCHOR.minus(Duration.ofMinutes(30)), "50.0", 900, "100.0"),
                activityAt(ANCHOR.minus(Duration.ofHours(1)), "50.0", 800, "100.0")));

        service.processTelemetry(DEVICE_ID, LIVESTOCK_ID, FARM_ID, DeviceType.CAPSULE,
                Map.of("temperature", 39.90), ANCHOR, "AGENTIC_PLATFORM");

        EstrusScore saved = captureSavedScore();
        // Legacy feature columns: increase-percent form and absolute deltas (not ratios ×100).
        assertEquals(100, saved.getStepIncreasePercent()); // recent3 2700 vs older4 0 → +100%
        assertBigDecimalEquals("1.40", saved.getTempDelta()); // 39.90 − 38.50
        assertBigDecimalEquals("300.0", saved.getDistanceDelta()); // 3×100 − 0
        // Score must equal what the untouched legacy kernel yields on those features.
        int expectedScore = new EstrusAnalysisService()
                .calculateScore(100, new BigDecimal("1.40"), new BigDecimal("300.0"));
        assertEquals(expectedScore, saved.getScore());
        // NIX-390 provenance: legacy formula stamped; the normalized-only
        // distance ratio column stays null on legacy rows.
        assertEquals("LEGACY", saved.getFeatureVersion());
        assertNull(saved.getDistanceRatio());
        // The legacy path must never touch the NIX-380 window read / anchor read.
        verify(activityLogRepo, never())
                .findWindowByLivestockId(anyLong(), any(), any(), anyInt());
        verify(tempLogRepo, never()).findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 1);
    }

    // ── 2. NORMALIZED basics: ratio 1.0 → low, ratio 3.0 → ≥70 + percent=300 ──

    @Test
    void normalized_crossingNotifiesAlertBridge_snapshotInstanceCarriesFlip() {
        // NIX-380 dev-smoke regression lock: the domain repo returns a FRESH
        // mapped instance per read, so when the scoring path re-loaded the
        // snapshot the >=70 flip landed on a different object and the alert
        // bridge (comparing against the caller's instance) never saw the
        // transition — the score row and snapshot updated but no alert. The
        // caller-loaded snapshot must be the one the score lands on.
        stubTemperatureChain();
        List<ActivityLog> logs = baselineWindows("60", null, null);
        logs.addAll(series(CURRENT_START, ANCHOR, "180", null, null));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        verify(healthAlertBridgeService, atLeastOnce())
                .syncAlertsWithSnapshot(any(HealthSnapshot.class), anyString());
    }

    @Test
    void normalized_dayBoundaryStraddle_meanMeanKeepsCleanCowQuiet() {
        // Simulation-forensics regression lock (NIX-380): a 6h window straddling
        // the morning day boundary carries a MINORITY of day frames (2/12).
        // Under the former mean/median pair the same-mix baseline pooled median
        // stayed in the night cluster (~13) while the current mean sat at ~27.3
        // → ratio 2.1 → 95-rung → a false ≥70 episode on a clean cow at every
        // morning boundary. Same-phase windows hold the identical frame mix, so
        // mean ÷ pooled mean cancels it: ratio 1.0 → no crossing (score is the
        // temp component alone, exactly like the flat ratio-1.0 case).
        stubTemperatureChain();
        stubWindowLogs(straddleWindows());

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        assertEquals(0, saved.getStepIncreasePercent()); // (1.0 − 1) × 100
        assertEquals(13, saved.getScore()); // round(42.0 × 0.3 / 1.0) — temp alone
        assertEquals("Not in estrus", saved.getAdvice());
        assertBigDecimalEquals("0.00", saved.getDistanceDelta()); // 27.25 − 27.25 meters
    }

    /** One 12-frame morning-boundary straddle: 10 night frames @15 then 2 day
     *  frames @88/89 — the shape observed on false episodes in the forensics. */
    private List<ActivityLog> straddleWindow(Instant start) {
        List<ActivityLog> logs = new ArrayList<>();
        for (int f = 0; f < 10; f++) {
            logs.add(activityAt(start.plus(Duration.ofMinutes(30L * f)), "15", 30, "15.0"));
        }
        logs.add(activityAt(start.plus(Duration.ofMinutes(300)), "88", 308, "88.0"));
        logs.add(activityAt(start.plus(Duration.ofMinutes(330)), "89", 312, "89.0"));
        return logs;
    }

    /** Current window + all 3 baseline windows, each with the SAME straddle mix
     *  (10 night + 2 day frames): mean 27.25 everywhere, ratio 1.0. */
    private List<ActivityLog> straddleWindows() {
        List<ActivityLog> logs = new ArrayList<>();
        logs.addAll(straddleWindow(SPAN_START));
        logs.addAll(straddleWindow(SPAN_START.plus(Duration.ofHours(24))));
        logs.addAll(straddleWindow(SPAN_START.plus(Duration.ofHours(48))));
        logs.addAll(straddleWindow(CURRENT_START));
        return logs;
    }


    @Test
    void normalized_ratioOne_lowScore_columnsCarryIncreaseAndMeterDelta() {
        stubTemperatureChain();
        // Current window 12 samples (mean 60), all baseline windows 60 → ratio 1.0.
        // Distance likewise flat at 100 → ratio 1.0.
        stubWindowLogs(spanSeries("60", null, "100.0"));

        processAnchorTelemetry();

        // Window read wiring: spans current + 3 baseline windows, clamped to maxWindowRows.
        verify(activityLogRepo).findWindowByLivestockId(
                eq(LIVESTOCK_ID), eq(SPAN_START), eq(ANCHOR), eq(estrusProps.getMaxWindowRows()));

        EstrusScore saved = captureSavedScore();
        // ratio 1.0 contributes nothing (ladder's [1.0, ratioMid) band starts at 0);
        // score is carried by tempDelta 0.55 alone: round(42.0 × 0.3 / 1.0) = 13.
        assertEquals(13, saved.getScore());
        assertEquals("Not in estrus", saved.getAdvice());
        assertEquals(0, saved.getStepIncreasePercent()); // (1.0 − 1) × 100 = 0 — no rise
        assertBigDecimalEquals("0.00", saved.getDistanceDelta()); // 100.0 − 100.0 meters
        assertBigDecimalEquals("0.55", saved.getTempDelta());
        assertBigDecimalEquals("38.50", saved.getBaselineUsed());
        assertEquals("DEFAULT", saved.getBaselineSource());
        assertNull(saved.getBaselineAlgorithmVersion());
    }

    @Test
    void normalized_ratioThree_crossesHighThreshold_stepIncreaseColumn200() {
        stubTemperatureChain();
        // Current ×3 (mean 180 vs baseline 60) → ratio 3.0; distance unavailable →
        // the kernel drops its weight instead of diluting with zeros.
        List<ActivityLog> logs = baselineWindows("60", null, null);
        logs.addAll(series(CURRENT_START, ANCHOR, "180", null, null));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        // Phase alignment: the baseline windows sit at exact 24h multiples of the
        // current window, so the circadian envelope cancels and the ratio equals
        // the true 3× level change — stepIncreasePercent 200 (= (3.0 − 1) × 100,
        // a genuine +200% rise) is that assertion.
        assertEquals(200, saved.getStepIncreasePercent());
        assertNull(saved.getDistanceDelta()); // distance component unavailable
        // round((100×0.4 + 42.0×0.3) / 0.7) = 75 ≥ 70 → high-estrus advice.
        assertEquals(75, saved.getScore());
        assertTrue(saved.getScore() >= 70);
        assertEquals("High estrus score. Breeding recommended within 12 hours.", saved.getAdvice());
        // NIX-390 provenance: normalized formula stamped; distance did not
        // participate, so the ratio column stays null alongside distanceDelta.
        assertEquals("NORMALIZED-V2", saved.getFeatureVersion());
        assertNull(saved.getDistanceRatio());
    }

    // ── 2b. NIX-390: featureVersion + distanceRatio persisted on NORMALIZED rows ──

    @Test
    void normalized_crossingWithDistance_persistsFeatureVersionAndConstructedRatio() {
        stubTemperatureChain();
        // Activity 60 → 180 (ratio 3.0) and distance 100.0 → 300.0 meters
        // (ratio 3.0): both components participate.
        List<ActivityLog> logs = baselineWindows("60", null, "100.0");
        logs.addAll(series(CURRENT_START, ANCHOR, "180", null, "300.0"));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        // 100×0.4 + 42×0.3 + 100×0.3 = 82.6 → 83 ≥ 70.
        assertEquals(83, saved.getScore());
        assertEquals("NORMALIZED-V2", saved.getFeatureVersion());
        assertBigDecimalEquals("3.000", saved.getDistanceRatio()); // 300.0 / 100.0
        assertBigDecimalEquals("200.00", saved.getDistanceDelta()); // 300.0 − 100.0 meters
        assertExplanationReproducesScore(saved);
    }

    @Test
    void normalized_distanceRatioBeyondColumn_clampedToDecimal6_3Bound() {
        // Lesson #13 lock: a near-zero distance baseline (1.0 m) against a
        // 2000 m current mean gives ratio 2000 — past DECIMAL(6,3)'s 999.999,
        // which would raise numeric field overflow and roll back the whole
        // telemetry transaction. The persisted ratio is clamped; the score is
        // unaffected (anything ≥ 3.0 already sits on the top rung).
        stubTemperatureChain();
        List<ActivityLog> logs = baselineWindows("60", null, "1.0");
        logs.addAll(series(CURRENT_START, ANCHOR, "180", null, "2000.0"));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        assertEquals(83, saved.getScore()); // 40 + 12.6 + 30 = 82.6 → 83
        assertBigDecimalEquals("999.999", saved.getDistanceRatio());
        assertExplanationReproducesScore(saved);
    }

    @Test
    void normalized_distanceRatioJustBelowRung_flooredNotRoundedOntoRung() {
        // Distance 10000.0 → 19996.0 m gives ratio 1.9996: the kernel scores
        // the mid rung (45). HALF_UP persistence would store 2.000 and the
        // explanation would jump onto the 2.0 rung (100 → recomputed 83 vs the
        // real 66); FLOOR stores 1.999, preserving the rung the score used.
        stubTemperatureChain();
        List<ActivityLog> logs = baselineWindows("60", null, "10000.0");
        logs.addAll(series(CURRENT_START, ANCHOR, "180", null, "19996.0"));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        // 100×0.4 + 42×0.3 + 45×0.3 = 40 + 12.6 + 13.5 = 66.1 → 66.
        assertEquals(66, saved.getScore());
        assertBigDecimalEquals("1.999", saved.getDistanceRatio());
        assertExplanationReproducesScore(saved);
    }

    /** End-to-end exactness: the explainer, fed only the persisted row,
     *  reproduces the score the scoring path stored. */
    private void assertExplanationReproducesScore(EstrusScore saved) {
        EstrusScoreExplainer explainer = new EstrusScoreExplainer(new EstrusAnalysisService(), estrusProps);
        EstrusScoreExplainer.EstrusScoreExplanation explanation = explainer.explain(saved);
        assertNotNull(explanation);
        EstrusAnalysisService.ComponentBreakdown b = explanation.breakdown();
        double raw = b.activityScore() * b.weightActivity()
                + b.temperatureScore() * b.weightTemperature()
                + b.distanceScore() * b.weightDistance();
        assertEquals((long) saved.getScore(), Math.round(Math.max(0, Math.min(100, raw))));
    }

    @Test
    void normalized_ratioBelowOne_negativeIncreaseAndNegativeMeterDelta() {
        stubTemperatureChain();
        // Current level below baseline: activityIndex 58 vs 100 → ratio 0.58;
        // distance likewise 58.0 vs 100.0 meters.
        List<ActivityLog> logs = baselineWindows("100", null, "100.0");
        logs.addAll(series(CURRENT_START, ANCHOR, "58", null, "58.0"));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        // (0.58 − 1) × 100 = −42 — a true negative rise under the 增幅% reading
        // (ratio×100 would have faked a −58% drop into a positive-looking column).
        assertEquals(-42, saved.getStepIncreasePercent());
        // Meter delta 58.0 − 100.0 = −42.00.
        assertBigDecimalEquals("-42.00", saved.getDistanceDelta());
        // Both ratios sit below 1.0 → both features score 0; score is carried by
        // tempDelta 0.55 alone over all three weights: round(42.0 × 0.3) = 13.
        assertEquals(13, saved.getScore());
    }

    // ── 3. CAPSULE-only: activityIndex channel, distance column null ──

    @Test
    void normalized_capsuleOnly_activityIndexScored_distanceColumnNull() {
        stubTemperatureChain();
        // Only activityIndex present (stepCount/distance null everywhere);
        // current 120 vs baseline 60 → ratio 2.0.
        List<ActivityLog> logs = baselineWindows("60", null, null);
        logs.addAll(series(CURRENT_START, ANCHOR, "120", null, null));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        assertEquals(100, saved.getStepIncreasePercent()); // (2.0 − 1) × 100 = +100%
        assertNull(saved.getDistanceDelta());
        // round((95×0.4 + 42.0×0.3) / 0.7) = 75 — CAPSULE-only scoring is not diluted.
        assertEquals(75, saved.getScore());
        assertEquals("NORMALIZED-V2", saved.getFeatureVersion());
        assertNull(saved.getDistanceRatio());
    }

    // ── 4. Ear-tag fallback: activityIndex all null → stepCount channel ──

    @Test
    void normalized_earTagFallback_stepCountChannelUsed() {
        stubTemperatureChain();
        // activityIndex null everywhere; stepCount current 600 vs baseline 200 → ratio 3.0.
        List<ActivityLog> logs = baselineWindows(null, 200, null);
        logs.addAll(series(CURRENT_START, ANCHOR, null, 600, null));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        EstrusScore saved = captureSavedScore();
        // The +200% (ratio 3.0) proves the stepCount channel produced the ratio.
        assertEquals(200, saved.getStepIncreasePercent());
        assertNull(saved.getDistanceDelta());
        assertEquals(75, saved.getScore());
    }

    // ── 5. Guards: fail silent, no row written ──────────────────

    @Test
    void guard_currentWindowSamplesBelowMin_noRowWritten() {
        stubTemperatureChain();
        // Baseline windows full, but only 3 samples inside the current window
        // (10:30 / 11:00 / 11:30) < minCurrentActivitySamples 4.
        List<ActivityLog> logs = baselineWindows("60", null, null);
        logs.addAll(series(ANCHOR.minus(Duration.ofMinutes(90)), ANCHOR, "60", null, null));
        stubWindowLogs(logs);

        processAnchorTelemetry();

        verify(estrusScoreRepo, never()).save(any());
    }

    @Test
    void guard_tooFewTemperatureSamples_noRowWritten() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(defaultSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 1))
                .thenReturn(List.of(tempAt(ANCHOR, "39.05")));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 7))
                .thenReturn(List.of(tempAt(ANCHOR, "39.05"))); // 1 < minTemperatureSamples 2

        processAnchorTelemetry();

        verify(estrusScoreRepo, never()).save(any());
    }

    @Test
    void guard_baselineWindowsAllUnqualified_noRowWritten() {
        stubTemperatureChain();
        // Current window full, but no baseline samples at all → baseline unavailable.
        stubWindowLogs(series(CURRENT_START, ANCHOR, "60", null, null));

        processAnchorTelemetry();

        verify(estrusScoreRepo, never()).save(any());
    }

    @Test
    void guard_noTemperatureAnchor_noRowWritten() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(defaultSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(LIVESTOCK_ID, 1))
                .thenReturn(List.of()); // no temperature → no anchor

        processAnchorTelemetry();

        verify(estrusScoreRepo, never()).save(any());
    }

    @Test
    void normalized_snapshotEstrusScoreUpdated() {
        stubTemperatureChain();
        stubWindowLogs(spanSeries("60", null, "100.0"));

        processAnchorTelemetry();

        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(LIVESTOCK_ID).orElseThrow();
        assertEquals(13, snapshot.getEstrusScore());
        // Saved twice per telemetry round: once by refreshSnapshot's own update,
        // once by the normalized scoring path's estrusScore update.
        verify(snapshotRepo, times(2)).save(snapshot);
    }

    // ── 6. Read clamp on the domain window read ─────────────────

    /**
     * Unit level for the new {@code findWindowByLivestockId(..., limit)} overload:
     * the Impl fetches the window ascending via the derived query and trims the
     * oldest rows past the limit — mocked at the JPA boundary (a real DB is not
     * needed to pin the clamp semantics).
     */
    @Nested
    class WindowReadClamp {

        private final ActivityLogJpaRepository jpaRepo = mock(ActivityLogJpaRepository.class);
        private final ActivityLogRepositoryImpl impl = new ActivityLogRepositoryImpl(jpaRepo);

        private List<ActivityLogJpaEntity> ascendingRows(int count) {
            List<ActivityLogJpaEntity> rows = new ArrayList<>();
            Instant start = Instant.parse("2026-06-04T00:00:00Z");
            for (int i = 0; i < count; i++) {
                ActivityLogJpaEntity row = new ActivityLogJpaEntity();
                row.setLivestockId(LIVESTOCK_ID);
                row.setDeviceId(DEVICE_ID);
                row.setActivityIndex(new BigDecimal("50.0"));
                row.setRecordedAt(start.plus(Duration.ofMinutes(30L * i)));
                rows.add(row);
            }
            return rows;
        }

        @Test
        void keepsNewestLimitRowsAndDropsOldest() {
            when(jpaRepo.findByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThanOrderByRecordedAtAsc(
                    eq(LIVESTOCK_ID), any(), any())).thenReturn(ascendingRows(10));

            List<ActivityLog> clamped = impl.findWindowByLivestockId(
                    LIVESTOCK_ID, Instant.parse("2026-06-04T00:00:00Z"), ANCHOR, 4);

            assertEquals(4, clamped.size());
            // Newest four kept (rows 6..9), ascending order preserved, oldest dropped.
            assertEquals(Instant.parse("2026-06-04T03:00:00Z"), clamped.get(0).getRecordedAt());
            assertEquals(Instant.parse("2026-06-04T04:30:00Z"), clamped.get(3).getRecordedAt());
        }

        @Test
        void limitLargerThanWindowReturnsAllRows() {
            when(jpaRepo.findByLivestockIdAndRecordedAtGreaterThanEqualAndRecordedAtLessThanOrderByRecordedAtAsc(
                    eq(LIVESTOCK_ID), any(), any())).thenReturn(ascendingRows(3));

            List<ActivityLog> clamped = impl.findWindowByLivestockId(
                    LIVESTOCK_ID, Instant.parse("2026-06-04T00:00:00Z"), ANCHOR, 600);

            assertEquals(3, clamped.size());
        }
    }
}
