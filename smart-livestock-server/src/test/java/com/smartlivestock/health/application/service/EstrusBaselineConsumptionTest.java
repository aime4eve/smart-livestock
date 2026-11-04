package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos;
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
import com.smartlivestock.identity.application.TenantZoneResolver;
import com.smartlivestock.iot.domain.model.DeviceType;
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
import java.time.LocalDate;
import java.time.ZoneOffset;
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
 * Task 4 of the individual baseline auto-learning plan (2026-11-03 §1.5):
 * estrus scoring consumes the snapshot's effective baseline (LEARNED vs
 * DEFAULT), stamps the four audit columns accordingly, and the daily fever
 * hours chart judges each log row by its own row delta instead of the fixed
 * 39.5°C threshold.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class EstrusBaselineConsumptionTest {

    private static final long FARM_ID = 1L;
    private static final long LIVESTOCK_ID = 10L;
    private static final long DEVICE_ID = 51L;
    private static final BigDecimal LEARNED_BASELINE = new BigDecimal("39.00");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");
    private static final Instant COMPUTED_AT = Instant.parse("2026-11-03T00:00:00Z");
    /** Noon of today/yesterday in UTC — stable day-bucket keys for the chart. */
    private static final Instant TODAY_NOON = LocalDate.now(ZoneOffset.UTC)
            .atStartOfDay(ZoneOffset.UTC).plusHours(12).toInstant();
    private static final Instant YESTERDAY_NOON = TODAY_NOON.minus(Duration.ofDays(1));

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
    @Mock private EstrusAnalysisService estrusAnalysisService;
    @Mock private EpidemicAnalysisService epidemicService;
    @Mock private HealthAnomalyService healthAnomalyService;
    @Mock private HealthAlertBridgeService healthAlertBridgeService;
    @Mock private com.smartlivestock.shared.common.MessageResolver messageResolver;
    @Mock private com.smartlivestock.ranch.application.signal.SignalRevisionService signalRevisionService;

    private final TenantZoneResolver tenantZoneResolver = mock(TenantZoneResolver.class);

    private BaselineLearningProperties properties;
    private HealthApplicationService service;

    @BeforeEach
    void setUp() {
        properties = new BaselineLearningProperties();
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
                feverService, digestiveService, estrusAnalysisService, epidemicService,
                messageResolver,
                mock(ContactAnalysisService.class),
                properties);

        when(tenantZoneResolver.zoneForFarm(anyLong(), any())).thenReturn(ZoneOffset.UTC);
        doNothing().when(snapshotRepo).ensureSnapshotExists(anyLong(), anyLong());
    }

    // ── helpers ─────────────────────────────────────────────────

    private HealthSnapshot learnedSnapshot() {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(LIVESTOCK_ID);
        snapshot.setFarmId(FARM_ID);
        snapshot.setBaselineSource("LEARNED");
        snapshot.setBaselineTemp(LEARNED_BASELINE);
        snapshot.setBaselineComputedAt(COMPUTED_AT);
        snapshot.setBaselineAlgorithmVersion("V1");
        return snapshot;
    }

    private TemperatureLog temp(String temperature, BigDecimal baseline) {
        TemperatureLog log = new TemperatureLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setDeviceId(DEVICE_ID);
        log.setTemperature(new BigDecimal(temperature));
        log.setBaselineTemp(baseline);
        log.setRecordedAt(Instant.now());
        return log;
    }

    private TemperatureLog tempOnDay(Instant noon, String temperature, BigDecimal baseline) {
        TemperatureLog log = temp(temperature, baseline);
        log.setRecordedAt(noon);
        return log;
    }

    private ActivityLog activity(int stepCount) {
        ActivityLog log = new ActivityLog();
        log.setLivestockId(LIVESTOCK_ID);
        log.setDeviceId(DEVICE_ID);
        log.setActivityIndex(new BigDecimal("50.0"));
        log.setStepCount(stepCount);
        log.setDistanceMeters(new BigDecimal("100.0"));
        log.setRecordedAt(Instant.now());
        return log;
    }

    /** Stubs the full processTelemetry → refreshSnapshot → triggerEstrusScoring
     *  chain: latest temp 39.90 over an older one, plus 3 activity logs. */
    private void stubScoringChain(HealthSnapshot snapshot) {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(eq(LIVESTOCK_ID), anyInt()))
                .thenReturn(List.of(
                        temp("39.90", LEARNED_BASELINE),
                        temp("38.90", DEFAULT_BASELINE)));
        when(activityLogRepo.findByLivestockIdOrderByRecordedAtDesc(eq(LIVESTOCK_ID), anyInt()))
                .thenReturn(List.of(activity(1000), activity(900), activity(800)));
        when(feverService.assessStatus(any(), any())).thenReturn(TempStatus.NORMAL);
        when(estrusAnalysisService.calculateScore(anyInt(), any(), any())).thenReturn(75);
        when(estrusAnalysisService.generateAdvice(anyInt())).thenReturn("Not in estrus");
    }

    private void processOneCapsuleTelemetry() {
        service.processTelemetry(DEVICE_ID, LIVESTOCK_ID, FARM_ID, DeviceType.CAPSULE,
                Map.of("temperature", 39.90),
                Instant.parse("2026-06-04T10:00:00Z"), "AGENTIC_PLATFORM");
    }

    private EstrusScore captureSavedScore() {
        ArgumentCaptor<EstrusScore> captor = ArgumentCaptor.forClass(EstrusScore.class);
        verify(estrusScoreRepo).save(captor.capture());
        return captor.getValue();
    }

    private static void assertZero(BigDecimal expected, BigDecimal actual) {
        assertNotNull(actual);
        assertEquals(0, expected.compareTo(actual),
                "expected " + expected + " but was " + actual);
    }

    private static double hoursOn(List<HealthDtos.DailyFeverHour> chart, String date) {
        return chart.stream()
                .filter(h -> h.date().equals(date))
                .findFirst()
                .map(HealthDtos.DailyFeverHour::hours)
                .orElseThrow(() -> new AssertionError("missing day bucket " + date));
    }

    // ── 1. LEARNED consumption ──────────────────────────────────

    @Test
    void learnedBaseline_consumedByScoring_andAudited() {
        HealthSnapshot snapshot = learnedSnapshot();
        stubScoringChain(snapshot);

        // Package-visible resolver: LEARNED + applyLearned → learned value.
        assertZero(LEARNED_BASELINE, service.effectiveEstrusBaseline(snapshot));

        processOneCapsuleTelemetry();

        EstrusScore saved = captureSavedScore();
        assertZero(new BigDecimal("0.90"), saved.getTempDelta()); // 39.90 − 39.00
        assertZero(LEARNED_BASELINE, saved.getBaselineUsed());
        assertEquals("LEARNED", saved.getBaselineSource());
        assertEquals("V1", saved.getBaselineAlgorithmVersion());
        assertEquals(COMPUTED_AT, saved.getBaselineComputedAt());
    }

    // ── 2. applyLearned=false rollback ──────────────────────────

    @Test
    void applyLearnedFalse_rollsBackToDefaultBaseline_everywhere() {
        HealthSnapshot snapshot = learnedSnapshot();
        stubScoringChain(snapshot);
        properties.setApplyLearned(false);

        // Rollback semantics: apply-learned=false always answers 38.50 even
        // when the snapshot still carries a learned baseline.
        assertZero(DEFAULT_BASELINE, service.effectiveEstrusBaseline(snapshot));

        processOneCapsuleTelemetry();

        EstrusScore saved = captureSavedScore();
        assertZero(new BigDecimal("1.40"), saved.getTempDelta()); // 39.90 − 38.50
        assertZero(DEFAULT_BASELINE, saved.getBaselineUsed());
        assertEquals("DEFAULT", saved.getBaselineSource());
        assertNull(saved.getBaselineAlgorithmVersion());
        assertNull(saved.getBaselineComputedAt());
    }

    // ── 3. DEFAULT cold start ───────────────────────────────────

    @Test
    void defaultColdStart_scoresWithFixedBaseline_andStampsDefault() {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(LIVESTOCK_ID);
        snapshot.setFarmId(FARM_ID);
        snapshot.setBaselineSource("DEFAULT");
        snapshot.setBaselineTemp(DEFAULT_BASELINE);
        stubScoringChain(snapshot);

        assertZero(DEFAULT_BASELINE, service.effectiveEstrusBaseline(snapshot));

        processOneCapsuleTelemetry();

        EstrusScore saved = captureSavedScore();
        assertZero(new BigDecimal("1.40"), saved.getTempDelta()); // 39.90 − 38.50
        assertZero(DEFAULT_BASELINE, saved.getBaselineUsed());
        assertEquals("DEFAULT", saved.getBaselineSource());
        assertNull(saved.getBaselineAlgorithmVersion());
        assertNull(saved.getBaselineComputedAt());
    }

    // ── 4. Fever chart: per-row delta ───────────────────────────

    @Test
    void feverDurationChart_judgesEachRowByItsOwnDelta() {
        when(subscriptionPort.hasFeature("health_score")).thenReturn(true);
        when(subscriptionPort.getRetentionDays("health_score")).thenReturn(365);
        // Row A: temp 39.80 over learned baseline 39.00 → delta 0.8 ≤ 1.0 —
        // the old fixed 39.5 threshold counted it (39.8 > 39.5); the new
        // per-row rule must NOT count it on its day.
        TemperatureLog learnedRow = tempOnDay(YESTERDAY_NOON, "39.80", LEARNED_BASELINE);
        // Row B: temp 40.20 over DEFAULT baseline 38.50 → delta 1.7 > 1.0 —
        // counts 0.5h as before.
        TemperatureLog defaultRow = tempOnDay(TODAY_NOON, "40.20", DEFAULT_BASELINE);
        when(tempLogRepo.findByLivestockIdAndTimeRange(eq(LIVESTOCK_ID), any(), any()))
                .thenReturn(List.of(learnedRow, defaultRow));

        List<HealthDtos.DailyFeverHour> chart =
                service.getFeverDurationChart(FARM_ID, LIVESTOCK_ID, null);

        String today = LocalDate.now(ZoneOffset.UTC).toString();
        String yesterday = LocalDate.now(ZoneOffset.UTC).minusDays(1).toString();
        assertEquals(0.0, hoursOn(chart, yesterday), 1e-9);
        assertEquals(0.5, hoursOn(chart, today), 1e-9);
    }

    // ── 5. Fever chart regression: all-DEFAULT rows ≡ old algorithm ──

    @Test
    void feverDurationChart_allDefaultRows_matchLegacyFixedThreshold() {
        when(subscriptionPort.hasFeature("health_score")).thenReturn(true);
        when(subscriptionPort.getRetentionDays("health_score")).thenReturn(365);
        // 39.80 > 39.5 in the legacy algorithm → must still count 0.5h.
        TemperatureLog counted = tempOnDay(TODAY_NOON, "39.80", DEFAULT_BASELINE);
        // Exactly 39.50 is NOT > 39.5 in the legacy algorithm → must stay 0.
        TemperatureLog onThreshold = tempOnDay(YESTERDAY_NOON, "39.50", DEFAULT_BASELINE);
        when(tempLogRepo.findByLivestockIdAndTimeRange(eq(LIVESTOCK_ID), any(), any()))
                .thenReturn(List.of(counted, onThreshold));

        List<HealthDtos.DailyFeverHour> chart =
                service.getFeverDurationChart(FARM_ID, LIVESTOCK_ID, null);

        String today = LocalDate.now(ZoneOffset.UTC).toString();
        String yesterday = LocalDate.now(ZoneOffset.UTC).minusDays(1).toString();
        assertEquals(0.5, hoursOn(chart, today), 1e-9);
        assertEquals(0.0, hoursOn(chart, yesterday), 1e-9);
    }

    // ── 6. ingest rollback: apply-learned=false falls back to default ──

    @Test
    void ingest_withSwitchOff_newLogsCarryDefaultBaseline() {
        properties.setApplyLearned(false);
        stubScoringChain(learnedSnapshot());

        ArgumentCaptor<TemperatureLog> logCaptor = ArgumentCaptor.forClass(TemperatureLog.class);
        service.processTelemetry(DEVICE_ID, LIVESTOCK_ID, FARM_ID, DeviceType.CAPSULE,
                Map.of("temperature", 39.90),
                Instant.parse("2026-06-04T10:00:00Z"), "AGENTIC_PLATFORM");
        verify(tempLogRepo).save(logCaptor.capture());
        TemperatureLog saved = logCaptor.getValue();
        // Plan §1.5 rollback: new logs fall back to the fixed default even
        // though the snapshot still carries a learned baseline.
        assertZero(DEFAULT_BASELINE, saved.getBaselineTemp());
        assertEquals("DEFAULT", saved.getBaselineSource());

        // The scoring side uses the same single decision (audit says DEFAULT).
        EstrusScore score = captureSavedScore();
        assertZero(DEFAULT_BASELINE, score.getBaselineUsed());
        assertEquals("DEFAULT", score.getBaselineSource());
    }
}
