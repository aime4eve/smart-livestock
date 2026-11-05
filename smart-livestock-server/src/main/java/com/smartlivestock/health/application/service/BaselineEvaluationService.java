package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineEvaluationReport;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.Side;
import com.smartlivestock.health.application.service.EstrusSeriesReplayer.ReplayResult;
import com.smartlivestock.health.application.service.EstrusSeriesReplayer.SideResult;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.BaselineLearningCalculator;
import com.smartlivestock.health.domain.service.BaselineLearningInput;
import com.smartlivestock.health.domain.service.BaselineLearningResult;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.identity.application.TenantZoneResolver;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;

/**
 * Read-only A/B evaluation of the individual temperature baseline
 * (plan 2026-11-03 Task 5). ONE identical event sequence (same livestock,
 * same recorded_at window, same temperatures and activities) is replayed
 * through the production estrus-scoring semantics twice — once with the
 * fixed 38.50 DEFAULT baseline, once with the LEARNED candidate the
 * learning kernel would produce for the same window — and each side is
 * aggregated into scoring points, ≥70 points and alert episodes.
 *
 * <p>Hard boundary: this is a <b>mechanism comparison on identical input</b>,
 * NOT a false-positive rate — real FPR/FNR need human-confirmed negative
 * labels (plan §0 交付边界). The service never writes scores, snapshots or
 * alerts: {@code @Transactional(readOnly = true)} and the learned candidate
 * is computed in memory and discarded.</p>
 *
 * <p>Since plan 2026-11-05 Task 3 the scoring replay itself lives in the
 * shared {@link EstrusSeriesReplayer} (also used by the datagen simulation
 * evaluation); this service only assembles inputs, resolves the learned
 * candidate and shapes the response — the semantics are unchanged.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BaselineEvaluationService {

    /**
     * Fixed cold-start baseline. Deliberately restated here instead of
     * widening {@code HealthApplicationService.DEFAULT_BASELINE_TEMP}
     * (private there): the two constants must stay aligned — 38.50 is the
     * documented cold-start baseline of the whole health pipeline.
     */
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    /**
     * Admin window override clamps to this range — the same range
     * {@link BaselineLearningProperties} enforces for the configured window.
     */
    private static final int MIN_WINDOW_DAYS = 7;
    private static final int MAX_WINDOW_DAYS = 14;

    /** Response disclaimer message key (AGENTS §4.1: no hardcoded user text). */
    static final String MECHANISM_NOTE_KEY = "health.baseline.evaluationNote";

    private static final String SOURCE_DEFAULT = "DEFAULT";

    private final BaselineLearningProperties properties;
    private final BaselineLearningCalculator calculator;
    private final BaselineLearningInputAssembler inputAssembler;
    private final HealthSnapshotRepository snapshotRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final EstrusSeriesReplayer replayer;
    private final TenantZoneResolver tenantZoneResolver;
    private final com.smartlivestock.shared.common.MessageResolver messageResolver;

    /**
     * Evaluate one livestock with the effective window
     * ({@code windowDaysOverride} clamped to 7-14, or the configured
     * default). Same queries, same timezone chain and same input assembly
     * as a production learning run; the learned candidate is never
     * persisted, and when the window does not qualify the learned side is
     * JSON {@code null} (reason {@code insufficient_data}, logged for
     * operations — the response note stays fixed by contract).
     */
    @Transactional(readOnly = true)
    public BaselineEvaluationReport evaluate(Long livestockId, Integer windowDaysOverride) {
        if (livestockId == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.health.baselineLivestockRequired");
        }
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "error.health.baselineSnapshotNotFound", new Object[]{livestockId}));

        int windowDays = resolveWindowDays(windowDaysOverride);
        Instant asOf = Instant.now();
        // Farm → tenant → platform default timezone chain (same as learning).
        ZoneId farmZone = tenantZoneResolver.zoneForFarm(snapshot.getFarmId(), null);
        Instant windowStart = asOf.minus(Duration.ofDays(windowDays));
        List<TemperatureLog> temperatures = tempLogRepo.findWindowByLivestockId(livestockId, windowStart, asOf);
        List<ActivityLog> activities = activityLogRepo.findWindowByLivestockId(livestockId, windowStart, asOf);

        // LEARNED candidate: identical assembly to a production learning run
        // (previousSource/previousBaselineTemp = the snapshot's current
        // values), computed in memory — never persisted.
        String previousSource = snapshot.getBaselineSource() != null
                ? snapshot.getBaselineSource() : SOURCE_DEFAULT;
        BaselineLearningInput input = inputAssembler.assemble(livestockId, snapshot, asOf,
                windowDays, farmZone, temperatures, activities);
        BaselineLearningResult learnedResult = calculator.calculate(input);

        // One replay pass over the shared component scores both candidates on
        // the identical normalized sequence (Task 3 refactor; semantics unchanged).
        boolean learnedAvailable = !learnedResult.insufficientData() && learnedResult.baselineTemp() != null;
        ReplayResult replay = replayer.replay(temperatures, activities, DEFAULT_BASELINE,
                learnedAvailable ? learnedResult.baselineTemp() : null);

        Side defaultSide = sideFor(DEFAULT_BASELINE, null, replay.defaultSide());
        Side learnedSide = null;
        if (learnedAvailable) {
            learnedSide = sideFor(learnedResult.baselineTemp(), learnedResult, replay.learnedSide());
        } else {
            // learnedSide stays null; the note is fixed by contract, so the
            // reason (insufficient_data) is surfaced for operations here only.
            log.info("Baseline evaluation learned side unavailable for livestock {}: "
                            + "insufficient_data (admittedSamples={}, qualifiedDays={})",
                    livestockId, learnedResult.admittedSampleCount(), learnedResult.qualifiedDays());
        }

        return new BaselineEvaluationReport(livestockId, windowStart, asOf, asOf,
                defaultSide, learnedSide, messageResolver.resolve(
                        MECHANISM_NOTE_KEY, null,
                        org.springframework.context.i18n.LocaleContextHolder.getLocale()));
    }

    /**
     * Merges ≥70 scoring positions into alert episodes (production
     * hasActiveAlert dedup approximation): times sorted ascending,
     * consecutive gaps ≤ 24h belong to the same episode, a larger gap starts
     * a new one. Package-visible so the merge rule can be unit-tested
     * directly; the implementation moved to the shared
     * {@link EstrusSeriesReplayer} in the Task 3 refactor and only
     * delegates here.
     */
    static int episodeCount(List<Instant> highScoreTimes) {
        return EstrusSeriesReplayer.episodeCount(highScoreTimes);
    }

    private Side sideFor(BigDecimal baseline, BaselineLearningResult evidence, SideResult stats) {
        return new Side(baseline,
                evidence == null ? null : evidence.bandLow(),
                evidence == null ? null : evidence.bandHigh(),
                evidence == null ? null : evidence.admittedSampleCount(),
                evidence == null ? null : evidence.qualifiedDays(),
                stats.scoringPoints(), stats.highScorePoints(),
                stats.episodes().size(),
                stats.lastTempDelta(), stats.lastScore());
    }

    /**
     * Window override clamp: null → the configured default, otherwise
     * bounded to 7-14 (same range the properties validation enforces).
     */
    private int resolveWindowDays(Integer override) {
        if (override == null) {
            return properties.getWindowDays();
        }
        return Math.max(MIN_WINDOW_DAYS, Math.min(MAX_WINDOW_DAYS, override));
    }
}
