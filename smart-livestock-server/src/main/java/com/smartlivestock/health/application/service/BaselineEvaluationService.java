package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineEvaluationReport;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.Side;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.BaselineLearningCalculator;
import com.smartlivestock.health.domain.service.BaselineLearningInput;
import com.smartlivestock.health.domain.service.BaselineLearningResult;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
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
import java.util.ArrayList;
import java.util.Comparator;
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

    /** Consecutive ≥70 scoring positions within this gap merge into one episode. */
    private static final Duration EPISODE_MERGE_GAP = Duration.ofHours(24);

    /** Response disclaimer message key (AGENTS §4.1: no hardcoded user text). */
    static final String MECHANISM_NOTE_KEY = "health.baseline.evaluationNote";

    private static final String SOURCE_DEFAULT = "DEFAULT";
    /** Production guard: the newest 7 rows feed each scoring position. */
    private static final int RECENT_WINDOW = 7;
    private static final int HIGH_SCORE_THRESHOLD = 70;

    private final BaselineLearningProperties properties;
    private final BaselineLearningCalculator calculator;
    private final BaselineLearningInputAssembler inputAssembler;
    private final HealthSnapshotRepository snapshotRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final EstrusAnalysisService estrusAnalysisService;
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

        Side defaultSide = sideFor(DEFAULT_BASELINE, null, replay(temperatures, activities, DEFAULT_BASELINE));
        Side learnedSide = null;
        if (!learnedResult.insufficientData() && learnedResult.baselineTemp() != null) {
            learnedSide = sideFor(learnedResult.baselineTemp(), learnedResult,
                    replay(temperatures, activities, learnedResult.baselineTemp()));
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
     * directly.
     */
    static int episodeCount(List<Instant> highScoreTimes) {
        if (highScoreTimes == null || highScoreTimes.isEmpty()) {
            return 0;
        }
        List<Instant> sorted = highScoreTimes.stream().sorted().toList();
        int episodes = 1;
        for (int i = 1; i < sorted.size(); i++) {
            if (Duration.between(sorted.get(i - 1), sorted.get(i)).compareTo(EPISODE_MERGE_GAP) > 0) {
                episodes++;
            }
        }
        return episodes;
    }

    /** Replay aggregation of one side before evidence fields are attached. */
    private record ReplayStats(int scoringPoints, int highScorePoints, List<Instant> highScoreTimes,
                               BigDecimal lastTempDelta, Integer lastScore) {
    }

    private Side sideFor(BigDecimal baseline, BaselineLearningResult evidence, ReplayStats stats) {
        return new Side(baseline,
                evidence == null ? null : evidence.bandLow(),
                evidence == null ? null : evidence.bandHigh(),
                evidence == null ? null : evidence.admittedSampleCount(),
                evidence == null ? null : evidence.qualifiedDays(),
                stats.scoringPoints(), stats.highScorePoints(),
                episodeCount(stats.highScoreTimes()),
                stats.lastTempDelta(), stats.lastScore());
    }

    /**
     * Replays the production estrus scoring over the event sequence with one
     * fixed baseline. For every temperature arrival (event-time position i)
     * the "latest 7 activities/temperatures as of that point" are pushed
     * through the production formulas — {@code calculateStepIncreasePercent}
     * (newest 3 vs the rest), {@code calculateDistanceDelta}, latest temp
     * minus the side's baseline — and scored via
     * {@link EstrusAnalysisService#calculateScore}. This mirrors
     * {@code HealthApplicationService.triggerEstrusScoring} minus every
     * write; positions with fewer than 3 activities or 2 temperatures are
     * skipped exactly like the production guard.
     */
    private ReplayStats replay(List<TemperatureLog> temperatures,
                               List<ActivityLog> activities, BigDecimal baseline) {
        List<TemperatureLog> tempsAsc = temperatures.stream()
                .filter(t -> t.getRecordedAt() != null && t.getTemperature() != null)
                .sorted(Comparator.comparing(TemperatureLog::getRecordedAt))
                .toList();
        List<ActivityLog> actsAsc = activities.stream()
                .filter(a -> a.getRecordedAt() != null)
                .sorted(Comparator.comparing(ActivityLog::getRecordedAt))
                .toList();

        int scoringPoints = 0;
        int highScorePoints = 0;
        List<Instant> highScoreTimes = new ArrayList<>();
        BigDecimal lastTempDelta = null;
        Integer lastScore = null;
        int actCursor = 0; // activities with recordedAt <= the current arrival

        for (int i = 0; i < tempsAsc.size(); i++) {
            Instant at = tempsAsc.get(i).getRecordedAt();
            while (actCursor < actsAsc.size() && !actsAsc.get(actCursor).getRecordedAt().isAfter(at)) {
                actCursor++;
            }
            // Production guard: recentActivities.size() < 3 || recentTemps.size() < 2 → skip.
            if (actCursor < 3 || i < 1) {
                continue;
            }
            // Production reads findByLivestockIdOrderByRecordedAtDesc(id, 7):
            // the newest rows as of this arrival, newest first.
            List<ActivityLog> recentActivities = newestFirst(actsAsc, actCursor);
            List<TemperatureLog> recentTemps = newestFirst(tempsAsc, i + 1);

            int stepIncreasePercent = stepIncreasePercent(recentActivities);
            BigDecimal tempDelta = recentTemps.get(0).getTemperature().subtract(baseline);
            BigDecimal distanceDelta = distanceDelta(recentActivities);
            int score = estrusAnalysisService.calculateScore(stepIncreasePercent, tempDelta, distanceDelta);

            scoringPoints++;
            if (score >= HIGH_SCORE_THRESHOLD) {
                highScorePoints++;
                highScoreTimes.add(at);
            }
            lastTempDelta = tempDelta;
            lastScore = score;
        }
        return new ReplayStats(scoringPoints, highScorePoints, highScoreTimes, lastTempDelta, lastScore);
    }

    /**
     * The last {@code count} rows (at most {@code RECENT_WINDOW}), newest
     * first — the in-memory equivalent of the production
     * {@code ...OrderByRecordedAtDesc(id, 7)} read at one arrival instant.
     */
    private static <T> List<T> newestFirst(List<T> ascending, int count) {
        int from = Math.max(0, count - RECENT_WINDOW);
        List<T> result = new ArrayList<>(count - from);
        for (int k = count - 1; k >= from; k--) {
            result.add(ascending.get(k));
        }
        return result;
    }

    /**
     * Production semantics copied verbatim from
     * {@code HealthApplicationService.calculateStepIncreasePercent}: the
     * newest 3 rows vs the rest of the latest-7 read. {@code logs} is
     * newest-first.
     */
    private int stepIncreasePercent(List<ActivityLog> logs) {
        if (logs.size() < 2) {
            return 0;
        }
        int recentSteps = logs.stream()
                .limit(3)
                .mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0)
                .sum();
        int olderSteps = logs.stream()
                .skip(3)
                .mapToInt(l -> l.getStepCount() != null ? l.getStepCount() : 0)
                .sum();
        if (olderSteps == 0) {
            return recentSteps > 0 ? 100 : 0;
        }
        return Math.round((float) (recentSteps - olderSteps) / olderSteps * 100);
    }

    /**
     * Production semantics copied verbatim from
     * {@code HealthApplicationService.calculateDistanceDelta}: newest-3
     * distance sum minus the rest. {@code logs} is newest-first.
     */
    private BigDecimal distanceDelta(List<ActivityLog> logs) {
        if (logs.size() < 2) {
            return BigDecimal.ZERO;
        }
        BigDecimal recentDist = logs.stream()
                .limit(3)
                .map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal olderDist = logs.stream()
                .skip(3)
                .map(l -> l.getDistanceMeters() != null ? l.getDistanceMeters() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return recentDist.subtract(olderDist);
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
