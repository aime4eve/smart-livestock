package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.CalvingPrediction;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.CalvingPredictionRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.CalvingPredictionService;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import com.smartlivestock.identity.application.TenantZoneResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Task 3 orchestration tests (NIX-381): feature gate, kernel wiring, the
 * persist/alert/release state machine over health_snapshots.calving_risk_score,
 * baseline audit stamping and column-scale clamping. The real kernel and the
 * real alert bridge run over mocked ports, so score oracles are hand-computed
 * from the documented ladders (weights 0.45/0.35/0.20).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CalvingPredictionApplicationServiceTest {

    private static final Long LIVESTOCK_ID = 10L;
    private static final Long FARM_ID = 1L;
    private static final Long TENANT_ID = 7L;
    private static final Instant NOW = Instant.parse("2026-11-06T12:00:00Z");
    private static final Instant COMPUTED_AT = Instant.parse("2026-11-01T00:00:00Z");
    /** UTC+8, no DST: fixed window-text expectations. */
    private static final ZoneId FARM_ZONE = ZoneId.of("Asia/Shanghai");
    private static final Duration STEP = Duration.ofMinutes(30);

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private CalvingPredictionRepository predictionRepo;
    @Mock private TemperatureLogRepository tempLogRepo;
    @Mock private ActivityLogRepository activityLogRepo;
    @Mock private DrinkingEventJpaRepository drinkingEventJpaRepository;
    @Mock private PhysiologyEventJpaRepository physiologyEventJpaRepository;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private HealthSubscriptionPort subscriptionPort;
    @Mock private TenantZoneResolver tenantZoneResolver;

    private CalvingPredictionProperties properties;
    private BaselineLearningProperties baselineProperties;
    private CalvingPredictionApplicationService service;

    @BeforeEach
    void setUp() {
        properties = new CalvingPredictionProperties();
        baselineProperties = new BaselineLearningProperties();
        HealthAlertBridgeService bridge = new HealthAlertBridgeService(
                ranchQueryPort, ranchCommandPort, tenantZoneResolver, properties);
        service = new CalvingPredictionApplicationService(
                new CalvingPredictionService(), properties, baselineProperties,
                snapshotRepo, predictionRepo, tempLogRepo, activityLogRepo,
                drinkingEventJpaRepository, physiologyEventJpaRepository,
                ranchQueryPort, subscriptionPort, bridge);
        service.setClock(Clock.fixed(NOW, ZoneOffset.UTC));

        when(ranchQueryPort.findTenantIdByFarm(FARM_ID)).thenReturn(Optional.of(TENANT_ID));
        when(subscriptionPort.hasFeatureForTenant(TENANT_ID, "calving_warning")).thenReturn(true);
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(null)));
        when(snapshotRepo.updateCalvingRiskScore(anyLong(), any())).thenReturn(1);
        when(predictionRepo.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(ranchQueryPort.findLivestockById(LIVESTOCK_ID)).thenReturn(Optional.of(
                new LivestockInfo(LIVESTOCK_ID, FARM_ID, "ST-22", "FEMALE", "HOLSTEIN")));
        when(tenantZoneResolver.zoneForFarm(eq(FARM_ID), any())).thenReturn(FARM_ZONE);
    }

    // ── gate ────────────────────────────────────────────────────

    @Test
    void gate_tenantResolutionFails_zeroQueriesZeroWrites() {
        when(ranchQueryPort.findTenantIdByFarm(FARM_ID)).thenReturn(Optional.empty());

        service.evaluateHead(LIVESTOCK_ID);

        verify(subscriptionPort, never()).hasFeatureForTenant(anyLong(), anyString());
        verify(tempLogRepo, never()).findWindowByLivestockId(anyLong(), any(), any());
        verify(activityLogRepo, never()).findWindowByLivestockId(anyLong(), any(), any());
        verify(predictionRepo, never()).save(any());
        verify(snapshotRepo, never()).updateCalvingRiskScore(anyLong(), any());
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    @Test
    void gate_featureLocked_zeroQueriesAfterGate() {
        when(subscriptionPort.hasFeatureForTenant(TENANT_ID, "calving_warning")).thenReturn(false);

        service.evaluateHead(LIVESTOCK_ID);

        verify(tempLogRepo, never()).findWindowByLivestockId(anyLong(), any(), any());
        verify(activityLogRepo, never()).findWindowByLivestockId(anyLong(), any(), any());
        verify(predictionRepo, never()).save(any());
        verify(snapshotRepo, never()).updateCalvingRiskScore(anyLong(), any());
        verify(ranchCommandPort, never()).createAlert(any());
    }

    // ── full pipeline ───────────────────────────────────────────

    /**
     * Hand-computed oracle for the default series: tempDrop 0.30 -> 100,
     * activityRatio 60/44 = 1.36 -> 70, prior neutral.
     * score = (100x0.45 + 70x0.35) / 0.8 = 86.875 -> 87.
     */
    @Test
    void firstAssessment_landsScoreWithoutTicket() {
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getFarmId()).isEqualTo(FARM_ID);
        assertThat(row.getLivestockId()).isEqualTo(LIVESTOCK_ID);
        assertThat(row.getRiskScore()).isEqualTo(87);
        assertThat(row.getTempDropCelsius()).isEqualByComparingTo("0.30");
        assertThat(row.getActivityRatio()).isEqualByComparingTo("1.36");
        assertThat(row.getPriorEnabled()).isFalse();
        // onset at now-2h -> signs window [now, now+28h], midpoint now+14h
        assertThat(row.getExpectedWindowStart()).isEqualTo(NOW);
        assertThat(row.getExpectedWindowEnd()).isEqualTo(NOW.plus(Duration.ofHours(28)));
        assertThat(row.getExpectedCalvingAt()).isEqualTo(NOW.plus(Duration.ofHours(14)));
        assertThat(row.getPredictedAt()).isEqualTo(NOW);
        assertThat(row.getBaselineUsed()).isEqualByComparingTo("38.50");
        assertThat(row.getBaselineSource()).isEqualTo("DEFAULT");
        assertThat(row.getBaselineComputedAt()).isNull();
        assertThat(row.getBaselineAlgorithmVersion()).isNull();

        verify(snapshotRepo).updateCalvingRiskScore(LIVESTOCK_ID, 87);
        // First crossing only lands the score: no ticket lookup at all.
        verify(ranchQueryPort, never()).hasActiveAlert(anyLong(), anyString());
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    @Test
    void secondAssessment_raisesTicketInOrder_withDatagenSourceAndWindow() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(87)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);
        stubReads(alertingTemps("DATAGEN"), alertingActivities("DATAGEN"));

        service.evaluateHead(LIVESTOCK_ID);

        // prev 87 >= 70 and new 87 >= 70 -> crossed -> raise (no ACTIVE ticket)
        InOrder ordering = inOrder(predictionRepo, ranchCommandPort);
        ordering.verify(predictionRepo).save(any());
        ordering.verify(ranchCommandPort).createAlert(any());
        // prev already carries 87 from the first crossing: same-value steady
        // state skips the targeted UPDATE.
        verify(snapshotRepo, never()).updateCalvingRiskScore(anyLong(), any());

        AlertInfo info = createdAlert();
        assertThat(info.farmId()).isEqualTo(FARM_ID);
        assertThat(info.livestockId()).isEqualTo(LIVESTOCK_ID);
        assertThat(info.alertType()).isEqualTo("CALVING_WARNING");
        assertThat(info.severity()).isEqualTo("WARNING");
        assertThat(info.source()).isEqualTo("DATAGEN");
        assertThat(info.messageKey()).isEqualTo("alert.health.calving.window");
        // display window = [max(window.start, now), window.end) in UTC+8
        assertThat(info.messageArgs()).isEqualTo(List.of("ST-22", "87", "11-06 20:00 ~ 11-08 00:00"));
        assertThat(info.message()).isEqualTo("牲畜 [ST-22] 临产风险偏高：87 分，预计分娩窗口 11-06 20:00 ~ 11-08 00:00");
    }

    @Test
    void persistenceOne_firstCrossing_raisesImmediately() {
        properties.setAlertPersistencePoints(1);
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        verify(ranchCommandPort).createAlert(any());
        verify(snapshotRepo).updateCalvingRiskScore(LIVESTOCK_ID, 87);
    }

    /**
     * Hand-computed oracle for the hold series: tempDrop 0.20 -> 70,
     * activityRatio 48/40 = 1.20 -> 45. score = (70x0.45 + 45x0.35)/0.8 = 59.
     */
    @Test
    void holdBand_activeTicket_keepsTicketAndTracksScore() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(72)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(true);
        stubReads(holdTemps("THINGSBOARD"), holdActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        assertThat(savedRow().getRiskScore()).isEqualTo(59);
        verify(snapshotRepo).updateCalvingRiskScore(LIVESTOCK_ID, 59);
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    /** tempDrop 0.15 -> 45 alone, no activity: score 45. */
    @Test
    void release_resolvesTicketAndClearsColumn() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(80)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(true);
        stubReads(releaseTemps("THINGSBOARD"), List.of());

        service.evaluateHead(LIVESTOCK_ID);

        assertThat(savedRow().getRiskScore()).isEqualTo(45);
        verify(snapshotRepo).updateCalvingRiskScore(LIVESTOCK_ID, null);
        verify(ranchCommandPort).resolveAlert(LIVESTOCK_ID, "CALVING_WARNING");
        verify(ranchCommandPort, never()).createAlert(any());
    }

    @Test
    void subPersistScore_resetsStaleColumnAndWritesNoRow() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(65)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);
        stubReads(releaseTemps("THINGSBOARD"), List.of());

        service.evaluateHead(LIVESTOCK_ID);

        verify(predictionRepo, never()).save(any());
        // Reset so a stale prev >= alert can never pair with a later crossing.
        verify(snapshotRepo).updateCalvingRiskScore(LIVESTOCK_ID, null);
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    @Test
    void steadySameValue_skipsColumnUpdateButWritesRow() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(59)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(true);
        stubReads(holdTemps("THINGSBOARD"), holdActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        assertThat(savedRow().getRiskScore()).isEqualTo(59);
        verify(snapshotRepo, never()).updateCalvingRiskScore(anyLong(), any());
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    @Test
    void quietHead_belowPersist_neverTouchesTicketLookup() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(null)));
        stubReads(releaseTemps("THINGSBOARD"), List.of());

        service.evaluateHead(LIVESTOCK_ID);

        verify(ranchQueryPort, never()).hasActiveAlert(anyLong(), anyString());
        verify(predictionRepo, never()).save(any());
        verify(snapshotRepo, never()).updateCalvingRiskScore(anyLong(), any());
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlert(anyLong(), anyString());
    }

    // ── baseline audit stamp ────────────────────────────────────

    @Test
    void baselineAudit_learnedStampedWhenConsumed() {
        HealthSnapshot snapshot = snapshot(null);
        snapshot.setBaselineSource("LEARNED");
        snapshot.setBaselineTemp(new BigDecimal("39.00"));
        snapshot.setBaselineComputedAt(COMPUTED_AT);
        snapshot.setBaselineAlgorithmVersion("V1");
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot));
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getBaselineUsed()).isEqualByComparingTo("39.00");
        assertThat(row.getBaselineSource()).isEqualTo("LEARNED");
        assertThat(row.getBaselineComputedAt()).isEqualTo(COMPUTED_AT);
        assertThat(row.getBaselineAlgorithmVersion()).isEqualTo("V1");
    }

    @Test
    void baselineAudit_forcedDefaultWhenApplyLearnedOff() {
        baselineProperties.setApplyLearned(false);
        HealthSnapshot snapshot = snapshot(null);
        snapshot.setBaselineSource("LEARNED");
        snapshot.setBaselineTemp(new BigDecimal("39.00"));
        snapshot.setBaselineComputedAt(COMPUTED_AT);
        snapshot.setBaselineAlgorithmVersion("V1");
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot));
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getBaselineUsed()).isEqualByComparingTo("38.50");
        assertThat(row.getBaselineSource()).isEqualTo("DEFAULT");
        assertThat(row.getBaselineComputedAt()).isNull();
        assertThat(row.getBaselineAlgorithmVersion()).isNull();
    }

    @Test
    void baselineAudit_learnedSnapshotWithoutValue_fallsBackToDefault() {
        HealthSnapshot snapshot = snapshot(null);
        snapshot.setBaselineSource("LEARNED");
        snapshot.setBaselineTemp(null);
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot));
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getBaselineUsed()).isEqualByComparingTo("38.50");
        assertThat(row.getBaselineSource()).isEqualTo("DEFAULT");
    }

    // ── column clamping / channel availability ──────────────────

    /** Activity ratio 100000/0.5 = 200000.00; DECIMAL(5,2) clamps to 999.99.
     *  No temperature: the activity-only score 100 is capped at 60. */
    @Test
    void activityRatio_clampedToColumnUpperBound() {
        List<ActivityLog> activities = new ArrayList<>();
        activities.addAll(actSeries(8, 16, "100000", "THINGSBOARD"));
        activities.addAll(actSeries(32, 4, "0.5", "THINGSBOARD"));
        stubReads(List.of(), activities);

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getRiskScore()).isEqualTo(60);
        assertThat(row.getTempDropCelsius()).isNull();
        assertThat(row.getActivityRatio()).isEqualByComparingTo("999.99");
        verify(ranchCommandPort, never()).createAlert(any());
    }

    @Test
    void clampToColumn_saturatesBothEndsAndKeepsNull() {
        assertThat(CalvingPredictionApplicationService.clampToColumn(new BigDecimal("1500.00"),
                CalvingPredictionApplicationService.ACTIVITY_RATIO_COLUMN_LIMIT))
                .isEqualByComparingTo("999.99");
        assertThat(CalvingPredictionApplicationService.clampToColumn(new BigDecimal("-150.00"),
                CalvingPredictionApplicationService.TEMP_DROP_COLUMN_LIMIT))
                .isEqualByComparingTo("-99.99");
        assertThat(CalvingPredictionApplicationService.clampToColumn(new BigDecimal("0.30"),
                CalvingPredictionApplicationService.TEMP_DROP_COLUMN_LIMIT))
                .isEqualByComparingTo("0.30");
        assertThat(CalvingPredictionApplicationService.clampToColumn(null,
                CalvingPredictionApplicationService.TEMP_DROP_COLUMN_LIMIT)).isNull();
    }

    // ── breeding prior ──────────────────────────────────────────

    /** BREEDING at now-275d: prior normal (270..293) but its due window
     *  [now+5d, now+15d] lies entirely after the signs window -> priorConflict,
     *  alert text without window. score = 45 + 24.5 + 20 = 89.5 -> 90. */
    @Test
    void priorConflict_alertTextWithoutWindow() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(90)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));
        when(physiologyEventJpaRepository
                .findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                        eq(LIVESTOCK_ID), any(), eq(PhysiologySource.MANUAL)))
                .thenReturn(Optional.of(physiologyEvent(PhysiologyEventType.BREEDING,
                        NOW.minus(Duration.ofDays(275)))));

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getRiskScore()).isEqualTo(90);
        assertThat(row.getPriorEnabled()).isTrue();
        // kernel estimate kept (signs window), conflict flagged
        assertThat(row.getExpectedWindowStart()).isEqualTo(NOW);
        assertThat(row.getExpectedWindowEnd()).isEqualTo(NOW.plus(Duration.ofHours(28)));

        AlertInfo info = createdAlert();
        assertThat(info.messageKey()).isEqualTo("alert.health.calving");
        assertThat(info.messageArgs()).isEqualTo(List.of("ST-22", "90"));
        assertThat(info.message()).isEqualTo("牲畜 [ST-22] 临产风险偏高：90 分");
    }

    @Test
    void gestation_latestMilestoneCalving_orOverdueOrFuture_priorUnavailable() {
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));

        // Latest milestone is a CALVING: that gestation ended, no prior.
        when(physiologyEventJpaRepository
                .findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                        eq(LIVESTOCK_ID), any(), eq(PhysiologySource.MANUAL)))
                .thenReturn(Optional.of(physiologyEvent(PhysiologyEventType.CALVING,
                        NOW.minus(Duration.ofDays(100)))));
        service.evaluateHead(LIVESTOCK_ID);

        // BREEDING beyond the 400-day horizon: no usable prior either.
        when(physiologyEventJpaRepository
                .findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                        eq(LIVESTOCK_ID), any(), eq(PhysiologySource.MANUAL)))
                .thenReturn(Optional.of(physiologyEvent(PhysiologyEventType.BREEDING,
                        NOW.minus(Duration.ofDays(401)))));
        service.evaluateHead(LIVESTOCK_ID);

        // Future-dated record: ignored.
        when(physiologyEventJpaRepository
                .findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                        eq(LIVESTOCK_ID), any(), eq(PhysiologySource.MANUAL)))
                .thenReturn(Optional.of(physiologyEvent(PhysiologyEventType.BREEDING,
                        NOW.plus(Duration.ofDays(1)))));
        service.evaluateHead(LIVESTOCK_ID);

        verify(ranchCommandPort, never()).createAlert(any());

        // All three evaluations scored >= persist: every one wrote a row, none
        // flagged a usable prior.
        ArgumentCaptor<CalvingPrediction> rows = ArgumentCaptor.forClass(CalvingPrediction.class);
        verify(predictionRepo, times(3)).save(rows.capture());
        assertThat(rows.getAllValues()).allSatisfy(row -> {
            assertThat(row.getPriorEnabled()).isFalse();
            assertThat(row.getRiskScore()).isEqualTo(87);
        });
    }

    // ── exclusion and source semantics ──────────────────────────

    /** A drinking event spanning the trailing 6h empties the stale lag
     *  (buffer 120min closes the window at now) -> temperature channel
     *  unavailable (tempDrop null, score capped at 60) while the activity
     *  series stays raw (ratio 1.36). The fetch lower bound is widened by
     *  the buffer: now - 78h - 2h = now - 80h. */
    @Test
    void drinkingExclusion_bufferedWindowsOnTemperatureOnly() {
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));
        DrinkingEventJpaEntity event = new DrinkingEventJpaEntity();
        event.setLivestockId(LIVESTOCK_ID);
        event.setEventStartAt(NOW.minus(Duration.ofHours(6)));
        event.setEventEndAt(NOW.minus(Duration.ofHours(2)));
        when(drinkingEventJpaRepository.findByLivestockIdAndEventStartAtLessThanAndEventEndAtGreaterThanEqual(
                eq(LIVESTOCK_ID), eq(NOW), eq(NOW.minus(Duration.ofHours(80)))))
                .thenReturn(List.of(event));

        service.evaluateHead(LIVESTOCK_ID);

        CalvingPrediction row = savedRow();
        assertThat(row.getTempDropCelsius()).isNull();
        assertThat(row.getActivityRatio()).isEqualByComparingTo("1.36");
        assertThat(row.getRiskScore()).isEqualTo(60);
        verify(ranchCommandPort, never()).createAlert(any());
    }

    /** An inverted row (trough before start) is clipped to its start. With the
     *  buffer widened to 240min the exclusion window becomes [now-2.5h, now+1.5h),
     *  dropping 5 of the 12 current-window samples below the guard; a naive
     *  end-at-trough read would build an inverted, never-matching window and
     *  keep all 12. */
    @Test
    void drinkingExclusion_troughBeforeStart_usesStartAsEnd() {
        properties.setDrinkingExclusionBufferMinutes(240);
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("THINGSBOARD"));
        DrinkingEventJpaEntity malformed = new DrinkingEventJpaEntity();
        malformed.setLivestockId(LIVESTOCK_ID);
        malformed.setEventStartAt(NOW.minus(Duration.ofMinutes(150)));
        malformed.setEventEndAt(NOW.minus(Duration.ofHours(6))); // end before start
        when(drinkingEventJpaRepository.findByLivestockIdAndEventStartAtLessThanAndEventEndAtGreaterThanEqual(
                eq(LIVESTOCK_ID), eq(NOW), eq(NOW.minus(Duration.ofHours(82)))))
                .thenReturn(List.of(malformed));

        assertThatCode(() -> service.evaluateHead(LIVESTOCK_ID)).doesNotThrowAnyException();
        assertThat(savedRow().getTempDropCelsius()).isNull();
    }

    /** Any synthetic sample marks the whole evaluation DATAGEN — even when the
     *  temperature lane itself is clean. */
    @Test
    void alertSource_syntheticActivityMarksTicketDatagen() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenReturn(Optional.of(snapshot(87)));
        when(ranchQueryPort.hasActiveAlert(LIVESTOCK_ID, "CALVING_WARNING")).thenReturn(false);
        stubReads(alertingTemps("THINGSBOARD"), alertingActivities("DATAGEN"));

        service.evaluateHead(LIVESTOCK_ID);

        assertThat(createdAlert().source()).isEqualTo("DATAGEN");
    }

    @Test
    void evaluateHead_swallowsRepositoryFailure() {
        when(snapshotRepo.findByLivestockId(LIVESTOCK_ID)).thenThrow(new IllegalStateException("db down"));

        assertThatCode(() -> service.evaluateHead(LIVESTOCK_ID)).doesNotThrowAnyException();
        verify(ranchCommandPort, never()).createAlert(any());
    }

    // ── helpers ─────────────────────────────────────────────────

    private HealthSnapshot snapshot(Integer prevScore) {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(LIVESTOCK_ID);
        snapshot.setFarmId(FARM_ID);
        snapshot.setCalvingRiskScore(prevScore);
        return snapshot;
    }

    private void stubReads(List<TemperatureLog> temperatures, List<ActivityLog> activities) {
        when(tempLogRepo.findWindowByLivestockId(eq(LIVESTOCK_ID), any(), eq(NOW))).thenReturn(temperatures);
        when(activityLogRepo.findWindowByLivestockId(eq(LIVESTOCK_ID), any(), eq(NOW))).thenReturn(activities);
    }

    private PhysiologyEventJpaEntity physiologyEvent(PhysiologyEventType type, Instant occurredAt) {
        PhysiologyEventJpaEntity event = new PhysiologyEventJpaEntity();
        event.setLivestockId(LIVESTOCK_ID);
        event.setEventType(type);
        event.setOccurredAt(occurredAt);
        event.setSource(PhysiologySource.MANUAL);
        return event;
    }

    /** 12 half-hour samples in [now-6h, now) at {@code current}, two same-phase
     *  reference windows at 38.80 -> drop = 38.80 - current. */
    private List<TemperatureLog> tempSeries(double fromHoursAgo, int count, String celsius, String source) {
        List<TemperatureLog> out = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            TemperatureLog log = new TemperatureLog();
            log.setLivestockId(LIVESTOCK_ID);
            log.setRecordedAt(NOW.minusSeconds(Math.round(fromHoursAgo * 3600)).plus(STEP.multipliedBy(i)));
            log.setTemperature(new BigDecimal(celsius));
            log.setSource(source);
            out.add(log);
        }
        return out;
    }

    private List<ActivityLog> actSeries(double fromHoursAgo, int count, String index, String source) {
        List<ActivityLog> out = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            ActivityLog log = new ActivityLog();
            log.setLivestockId(LIVESTOCK_ID);
            log.setRecordedAt(NOW.minusSeconds(Math.round(fromHoursAgo * 3600)).plus(STEP.multipliedBy(i)));
            log.setActivityIndex(new BigDecimal(index));
            log.setSource(source);
            out.add(log);
        }
        return out;
    }

    /** tempDrop 0.30 (score 100) + activityRatio 1.36 (score 70) -> 87. */
    private List<TemperatureLog> alertingTemps(String source) {
        List<TemperatureLog> all = new ArrayList<>();
        all.addAll(tempSeries(6, 12, "38.50", source));
        all.addAll(tempSeries(30, 12, "38.80", source));
        all.addAll(tempSeries(54, 12, "38.80", source));
        return all;
    }

    private List<ActivityLog> alertingActivities(String source) {
        List<ActivityLog> all = new ArrayList<>();
        all.addAll(actSeries(8, 16, "60", source));
        all.addAll(actSeries(32, 16, "40", source));
        all.addAll(actSeries(56, 4, "48", source));
        return all;
    }

    /** tempDrop 0.20 (score 70) + activityRatio 1.20 (score 45) -> 59. */
    private List<TemperatureLog> holdTemps(String source) {
        List<TemperatureLog> all = new ArrayList<>();
        all.addAll(tempSeries(6, 12, "38.60", source));
        all.addAll(tempSeries(30, 12, "38.80", source));
        all.addAll(tempSeries(54, 12, "38.80", source));
        return all;
    }

    private List<ActivityLog> holdActivities(String source) {
        List<ActivityLog> all = new ArrayList<>();
        all.addAll(actSeries(8, 16, "48", source));
        all.addAll(actSeries(32, 16, "40", source));
        return all;
    }

    /** tempDrop 0.15 (score 45), no activity -> 45. */
    private List<TemperatureLog> releaseTemps(String source) {
        List<TemperatureLog> all = new ArrayList<>();
        all.addAll(tempSeries(6, 12, "38.65", source));
        all.addAll(tempSeries(30, 12, "38.80", source));
        all.addAll(tempSeries(54, 12, "38.80", source));
        return all;
    }

    private CalvingPrediction savedRow() {
        ArgumentCaptor<CalvingPrediction> captor = ArgumentCaptor.forClass(CalvingPrediction.class);
        verify(predictionRepo, times(1)).save(captor.capture());
        return captor.getValue();
    }

    private AlertInfo createdAlert() {
        ArgumentCaptor<AlertInfo> captor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort, times(1)).createAlert(captor.capture());
        return captor.getValue();
    }
}
