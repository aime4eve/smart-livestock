package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.CalvingPrediction;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.CalvingPredictionRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.CalvingPredictionService;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ActivitySample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.AlertTransition;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ExclusionWindow;
import com.smartlivestock.health.domain.service.CalvingPredictionService.TempSample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.WindowEstimate;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * Orchestrates one calving-risk evaluation of a single livestock (NIX-381
 * Task 3, plan 2026-11-06 "触发模型与调用链" / "告警与可见面"): feature gate →
 * event-time window reads → the pure {@link CalvingPredictionService} kernel →
 * persistence-aware alert state machine → {@link HealthAlertBridgeService}.
 *
 * <h2>Alert state machine</h2>
 * The only state is {@code health_snapshots.calving_risk_score} ({@code prev};
 * null = never scored or released) plus the ACTIVE ticket itself — no Redis.
 * The decision rules below were extracted in Task 4 into the pure kernel
 * functions {@link CalvingPredictionService#transition} /
 * {@link CalvingPredictionService#crossedAlert} so the simulation replayer
 * replays the identical transitions; this class only owns the I/O around
 * them (the guarded ticket lookup and the writes).
 * <ul>
 *   <li><b>crossed</b>: the score has persisted at/above the alert threshold —
 *       {@code new >= alert} when alertPersistencePoints is 1, otherwise
 *       {@code prev >= alert && new >= alert} (review 2b: the first crossing
 *       only lands the score). The column holds one previous score, so any
 *       alertPersistencePoints above 2 behaves as 2.</li>
 *   <li><b>raise</b> = crossed and no ACTIVE CALVING_WARNING ticket.</li>
 *   <li><b>release</b> = an ACTIVE ticket and {@code new < release} — immediate.
 *       Between release and alert (hold band 55–70) an ACTIVE ticket stays.</li>
 *   <li>The ticket lookup only runs when crossed or {@code prev != null}: raise
 *       and release commit together with the column in this transaction, so
 *       an ACTIVE ticket implies a non-null column (orphans are healed by
 *       {@link StaleHealthAlertReconciler}); never-scored heads cost no lookup.</li>
 * </ul>
 *
 * <h2>Write discipline (steady state writes nothing)</h2>
 * <ul>
 *   <li>calving_predictions row: {@code new >= persist}, a raise or a release.</li>
 *   <li>Column via the targeted UPDATE only, never a whole-entity save (three
 *       writers share the snapshot row): release → NULL; {@code new >= persist},
 *       a raise or an ACTIVE ticket (hold band tracking) → new, skipped when equal
 *       to prev; a non-null prev with a sub-persist score and no ticket → NULL
 *       (reset, so a stale {@code prev >= alert} can never pair with a later
 *       crossing as two "consecutive" evaluations); otherwise untouched.</li>
 * </ul>
 *
 * <p>Transaction design mirrors {@link HealthAnomalyService#assess}:
 * {@code REQUIRES_NEW}, every failure is logged and swallowed so one head can
 * never fail the scheduler batch or a caller's transaction. The targeted
 * UPDATE clears the persistence context, so every value the bridge needs is
 * captured as a plain value before it.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CalvingPredictionApplicationService {

    /** Feature gate seeded by V20261106130000 (premium/enterprise open). */
    static final String FEATURE_KEY = "calving_warning";
    static final String ALERT_TYPE = "CALVING_WARNING";
    /** Fixed default baseline stamped when no learned baseline is consumed. */
    static final BigDecimal DEFAULT_BASELINE_TEMP = new BigDecimal("38.50");
    /** A BREEDING record older than this no longer describes the current gestation. */
    static final long MAX_GESTATION_DAYS = 400;
    /** calving_predictions.temp_drop_celsius is DECIMAL(4,2). */
    static final BigDecimal TEMP_DROP_COLUMN_LIMIT = new BigDecimal("99.99");
    /** calving_predictions.activity_ratio is DECIMAL(5,2). */
    static final BigDecimal ACTIVITY_RATIO_COLUMN_LIMIT = new BigDecimal("999.99");

    private static final String SOURCE_DATAGEN = "DATAGEN";
    private static final String SOURCE_UNKNOWN = "UNKNOWN";
    private static final String BASELINE_DEFAULT = "DEFAULT";
    private static final String BASELINE_LEARNED = "LEARNED";
    /** Latest of these milestones decides the gestation: BREEDING starts one, CALVING ends it. */
    private static final List<PhysiologyEventType> GESTATION_MILESTONES =
            List.of(PhysiologyEventType.BREEDING, PhysiologyEventType.CALVING);

    private final CalvingPredictionService calvingKernel;
    private final CalvingPredictionProperties properties;
    private final BaselineLearningProperties baselineLearningProperties;
    private final HealthSnapshotRepository snapshotRepo;
    private final CalvingPredictionRepository predictionRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final DrinkingEventJpaRepository drinkingEventJpaRepository;
    private final PhysiologyEventJpaRepository physiologyEventJpaRepository;
    private final RanchQueryPort ranchQueryPort;
    private final HealthSubscriptionPort subscriptionPort;
    private final HealthAlertBridgeService alertBridge;

    /** Evaluation clock; replaced only by unit tests (event-time windows need a fixed now). */
    private Clock clock = Clock.systemUTC();

    /**
     * Evaluate one livestock at the current instant. Never throws: failures
     * are logged and swallowed (see class javadoc).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void evaluateHead(Long livestockId) {
        try {
            doEvaluate(livestockId);
        } catch (Exception e) {
            log.warn("Calving evaluation failed (suppressed) for livestock [{}]: {}", livestockId, e.getMessage());
            // Do NOT rethrow — a REQUIRES_NEW failure must never stop the
            // scheduler batch or corrupt a caller's transaction.
        }
    }

    void setClock(Clock clock) {
        this.clock = clock;
    }

    private void doEvaluate(Long livestockId) {
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
        if (snapshot == null) {
            log.debug("Calving evaluation skipped: no health snapshot for livestock {}", livestockId);
            return;
        }
        // The scheduler trigger instant; half-open windows never read a sample at now.
        Instant now = clock.instant();
        Long farmId = snapshot.getFarmId();

        // 1. Feature gate with an explicit tenant: the scheduler thread has no
        //    TenantContext, so hasFeature() would fall back to basic and lock it.
        Optional<Long> tenantId = ranchQueryPort.findTenantIdByFarm(farmId);
        if (tenantId.isEmpty()) {
            log.warn("Calving evaluation skipped: farm {} resolves to no tenant (livestock {})", farmId, livestockId);
            return;
        }
        if (!subscriptionPort.hasFeatureForTenant(tenantId.get(), FEATURE_KEY)) {
            log.debug("Calving evaluation skipped: {} locked for tenant {} (livestock {})",
                    FEATURE_KEY, tenantId.get(), livestockId);
            return;
        }

        // 2. Event-time window reads (half-open [from, now)).
        CalvingPredictionProperties p = properties;
        Instant tempFrom = now.minus(Duration.ofHours(tempLookbackHours(p)));
        Instant activityFrom = now.minus(Duration.ofHours(activityLookbackHours(p)));
        List<TemperatureLog> temperatures = tempLogRepo.findWindowByLivestockId(livestockId, tempFrom, now);
        List<ActivityLog> activities = activityLogRepo.findWindowByLivestockId(livestockId, activityFrom, now);
        List<ExclusionWindow> drinking = drinkingExclusionWindows(livestockId, tempFrom, now, p);
        Integer gestationDays = gestationDays(livestockId, now, p);

        // 3. Kernel. Drinking exclusion applies to the temperature channel only
        //    (review 2b): activity stays raw.
        List<TempSample> rawTemps = temperatures.stream()
                .map(t -> new TempSample(t.getRecordedAt(), t.getTemperature()))
                .toList();
        List<ActivitySample> rawActivities = activities.stream()
                .map(a -> new ActivitySample(a.getRecordedAt(), a.getActivityIndex()))
                .toList();
        List<TempSample> cleanTemps = CalvingPredictionService.excludeWindows(rawTemps, drinking);

        BigDecimal tempDrop = calvingKernel.computeTempDrop(cleanTemps, now, p);
        BigDecimal activityRatio = calvingKernel.computeActivityRatio(rawActivities, now, p);
        boolean rebound = calvingKernel.isReboundDetected(cleanTemps, now, p);
        int score = calvingKernel.score(tempDrop, activityRatio, gestationDays, rebound, p);
        Optional<Instant> onset = calvingKernel.detectOnset(cleanTemps, now, p);
        // Same definition as the replayer (review 2b hand-off).
        boolean activityRiseSeen = activityRatio != null && calvingKernel.activityRatioScore(activityRatio, p) > 0;
        WindowEstimate window = calvingKernel.estimateWindow(now, onset, activityRiseSeen, gestationDays, p);

        // 4. State machine (see class javadoc) — shared kernel function since
        //    the Task 4 extraction, so the simulation replayer decides the
        //    identical transitions. The ticket lookup only runs when crossed
        //    or a score is stored; transition() re-guards internally, so the
        //    guarded result passed here reproduces the decision exactly.
        Integer prev = snapshot.getCalvingRiskScore();
        boolean crossed = calvingKernel.crossedAlert(prev, score, p);
        boolean alertActive = (crossed || prev != null)
                && ranchQueryPort.hasActiveAlert(livestockId, ALERT_TYPE);
        AlertTransition transition = calvingKernel.transition(prev, score, alertActive, p);
        boolean raise = transition.raise();
        boolean release = transition.release();
        Integer columnValue = transition.newColumnValue();
        boolean writeColumn = transition.storeColumn(prev);
        boolean writeRow = transition.storeRow();

        // 5. Plain values for the bridge, captured BEFORE the targeted UPDATE
        //    (clearAutomatically detaches everything loaded in this transaction).
        String alertSource = alertSource(temperatures, activities);
        Instant displayStart = null;
        Instant displayEnd = null;
        if (window.isEstimated() && !window.priorConflict()) {
            // A window starting in the past is shown from now on; prior conflict
            // or no estimate keeps the window out of the alert text.
            displayStart = window.start().isAfter(now) ? window.start() : now;
            displayEnd = window.end();
        }

        // 6. Writes: history row, then the column, then the ticket.
        if (writeRow) {
            predictionRepo.save(buildPrediction(snapshot, livestockId, farmId, score, tempDrop,
                    activityRatio, gestationDays, window, now));
        }
        if (writeColumn) {
            int updated = snapshotRepo.updateCalvingRiskScore(livestockId, columnValue);
            if (updated == 0) {
                log.warn("Calving risk update matched no snapshot row for livestock {}", livestockId);
            }
        }
        if (raise) {
            alertBridge.syncCalvingAlert(farmId, livestockId, score, displayStart, displayEnd, alertSource);
        } else if (release) {
            alertBridge.syncCalvingAlert(farmId, livestockId, score, null, alertSource);
        }

        log.debug("Calving evaluation livestock={} score={} prev={} tempDrop={} activityRatio={} "
                        + "gestationDays={} rebound={} crossed={} raise={} release={}",
                livestockId, score, prev, tempDrop, activityRatio, gestationDays, rebound,
                crossed, raise, release);
    }

    /**
     * Temperature read span covering every window the kernel may touch:
     * stale-window lag + oldest same-phase offset + window width (defaults
     * 24 + 48 + 6 = 78h); the rebound lookback (12h) normally fits inside.
     */
    static long tempLookbackHours(CalvingPredictionProperties p) {
        long staleSpan = p.getStaleWindowMaxLagHours() + maxOffset(p.getRefWindowOffsetHours())
                + p.getCurrentTempWindowHours();
        return Math.max(staleSpan, p.getReboundLookbackHours());
    }

    /** Activity read span: oldest same-phase offset + window width (defaults 48 + 8 = 56h). */
    static long activityLookbackHours(CalvingPredictionProperties p) {
        return maxOffset(p.getRefActivityWindowOffsetHours()) + p.getCurrentActivityWindowHours();
    }

    private static long maxOffset(List<Long> offsets) {
        return offsets == null ? 0 : offsets.stream()
                .filter(Objects::nonNull).mapToLong(Long::longValue).max().orElse(0);
    }

    /**
     * Drinking exclusion windows for the temperature channel (review 2b/2c):
     * {@code [event_start_at, max(event_start_at, event_end_at) + buffer)}.
     * In drinking_events {@code event_start_at} is the descent onset and
     * {@code event_end_at} the trough (MANUAL rows store end == start), so the
     * buffer stretches each window over the post-trough recovery — the same
     * span the baseline learner excludes. The max() guards a malformed row
     * whose end precedes its start. Events are fetched back to
     * {@code from − buffer} so one that troughed just before the read window
     * still covers its edge samples. Labels are not filtered, exactly like the
     * baseline learner's exclusion fetch.
     */
    private List<ExclusionWindow> drinkingExclusionWindows(Long livestockId, Instant from, Instant now,
                                                           CalvingPredictionProperties p) {
        Duration buffer = Duration.ofMinutes(p.getDrinkingExclusionBufferMinutes());
        return drinkingEventJpaRepository
                .findByLivestockIdAndEventStartAtLessThanAndEventEndAtGreaterThanEqual(
                        livestockId, now, from.minus(buffer))
                .stream()
                .map(event -> {
                    Instant start = event.getEventStartAt();
                    Instant trough = event.getEventEndAt();
                    Instant end = trough == null || trough.isBefore(start) ? start : trough;
                    return new ExclusionWindow(start, end.plus(buffer));
                })
                .toList();
    }

    /**
     * Days pregnant as of {@code now} for the breeding prior, from the latest
     * MANUAL BREEDING-or-CALVING milestone (the existing stage-derivation
     * finder; MANUAL is the only source with a write path). Null — prior
     * unavailable — when the prior is switched off, when there is no
     * milestone, when the latest milestone is a CALVING (that gestation
     * already ended), when it is dated after now, or when it is older than
     * {@link #MAX_GESTATION_DAYS}.
     */
    private Integer gestationDays(Long livestockId, Instant now, CalvingPredictionProperties p) {
        if (!p.isUseBreedingPrior()) {
            return null;
        }
        return physiologyEventJpaRepository
                .findFirstByLivestockIdAndEventTypeInAndSourceOrderByOccurredAtDesc(
                        livestockId, GESTATION_MILESTONES, PhysiologySource.MANUAL)
                .filter(event -> event.getEventType() == PhysiologyEventType.BREEDING)
                .map(PhysiologyEventJpaEntity::getOccurredAt)
                .filter(at -> at != null && !at.isAfter(now))
                .map(at -> ChronoUnit.DAYS.between(at, now))
                .filter(days -> days <= MAX_GESTATION_DAYS)
                .map(Long::intValue)
                .orElse(null);
    }

    /**
     * Ticket source of this evaluation: DATAGEN as soon as any sample read is
     * synthetic — a score that consumed simulation data must never pass for a
     * real rule alert (multi-source red line) — otherwise the source of the
     * newest temperature sample (the bridge maps every non-DATAGEN value to
     * RULE). Taken from the samples, not the snapshot: simulated herds write
     * the logs directly and never set the snapshot's current-temp source.
     */
    static String alertSource(List<TemperatureLog> temperatures, List<ActivityLog> activities) {
        boolean synthetic = temperatures.stream().anyMatch(t -> SOURCE_DATAGEN.equals(t.getSource()))
                || activities.stream().anyMatch(a -> SOURCE_DATAGEN.equals(a.getSource()));
        if (synthetic) {
            return SOURCE_DATAGEN;
        }
        return temperatures.stream()
                .filter(t -> t.getRecordedAt() != null && t.getSource() != null)
                .max(Comparator.comparing(TemperatureLog::getRecordedAt))
                .map(TemperatureLog::getSource)
                .orElse(SOURCE_UNKNOWN);
    }

    private CalvingPrediction buildPrediction(HealthSnapshot snapshot, Long livestockId, Long farmId,
                                              int score, BigDecimal tempDrop, BigDecimal activityRatio,
                                              Integer gestationDays, WindowEstimate window, Instant now) {
        CalvingPrediction row = new CalvingPrediction();
        row.setFarmId(farmId);
        row.setLivestockId(livestockId);
        row.setRiskScore(score);
        row.setTempDropCelsius(clampToColumn(tempDrop, TEMP_DROP_COLUMN_LIMIT));
        row.setActivityRatio(clampToColumn(activityRatio, ACTIVITY_RATIO_COLUMN_LIMIT));
        // A usable breeding record fed this evaluation (switch on + BREEDING
        // within MAX_GESTATION_DAYS) — splits rows into the "no record" /
        // "record available" evaluation scenarios (review 2c).
        row.setPriorEnabled(properties.isUseBreedingPrior() && gestationDays != null);
        // The kernel estimate as is (unclipped, conflict included); only the
        // alert text uses the display window.
        row.setExpectedWindowStart(window.start());
        row.setExpectedWindowEnd(window.end());
        row.setExpectedCalvingAt(window.midpoint());
        row.setPredictedAt(now);

        // Baseline audit stamp. Same decision as
        // HealthApplicationService.usesLearnedBaseline (duplicated on purpose:
        // that class stays untouched in NIX-381; extracting one shared helper
        // is a follow-up). DEFAULT rows carry null computedAt/version.
        boolean learnedApplied = baselineLearningProperties.isApplyLearned()
                && BASELINE_LEARNED.equals(snapshot.getBaselineSource())
                && snapshot.getBaselineTemp() != null;
        row.setBaselineUsed(learnedApplied ? snapshot.getBaselineTemp() : DEFAULT_BASELINE_TEMP);
        row.setBaselineSource(learnedApplied ? BASELINE_LEARNED : BASELINE_DEFAULT);
        row.setBaselineComputedAt(learnedApplied ? snapshot.getBaselineComputedAt() : null);
        row.setBaselineAlgorithmVersion(learnedApplied ? snapshot.getBaselineAlgorithmVersion() : null);
        return row;
    }

    /**
     * Saturates a feature to its DECIMAL column range (numeric overflow would
     * fail the whole evaluation). The ladder score is already saturated far
     * below these limits, so a clamped row still reproduces its score.
     */
    static BigDecimal clampToColumn(BigDecimal value, BigDecimal limit) {
        if (value == null) {
            return null;
        }
        if (value.compareTo(limit) > 0) {
            return limit;
        }
        BigDecimal floor = limit.negate();
        return value.compareTo(floor) < 0 ? floor : value;
    }
}
