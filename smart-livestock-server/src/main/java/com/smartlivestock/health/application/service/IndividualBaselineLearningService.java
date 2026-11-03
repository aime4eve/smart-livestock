package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.BaselineLearningCalculator;
import com.smartlivestock.health.domain.service.BaselineLearningInput;
import com.smartlivestock.health.domain.service.BaselineLearningResult;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.identity.application.TenantZoneResolver;
import com.smartlivestock.shared.cache.RedisCacheService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;

/**
 * Orchestrates one individual temperature baseline learning run for a single
 * livestock (plan 2026-11-03 Task 3). Thin application shell around the pure
 * {@link BaselineLearningCalculator}: fetches the event-time window data and
 * delegates the kernel-input assembly (exclusion windows, tuning) to the
 * shared {@link BaselineLearningInputAssembler} — the read-only admin A/B
 * evaluation reuses the very same assembly so a learned candidate can never
 * drift from a production run — then persists a learned baseline through a
 * targeted snapshot UPDATE.
 *
 * <p>Transaction design: {@code REQUIRES_NEW} so a learning run is an
 * independent unit of work — the scheduler has no outer transaction and the
 * telemetry-consuming path is never extended by a full-window scan. The
 * method does not need its own try/catch: the scheduler catches per head so
 * one bad livestock cannot stop the batch.</p>
 *
 * <p>Concurrency: a Redis SET-NX key ({@code baseline-learning:recalc:<id>})
 * throttles + serializes per-livestock runs; manual recalculations bypass it.
 * The learned-baseline write is a targeted UPDATE (never a whole-entity save)
 * so it cannot clobber the read-modify-write that processTelemetry performs
 * on the same row (plan §1.4). No signal event is fired on a new baseline:
 * the baseline is a slow-moving variable, unlike the metric changes that
 * bump farm signal revisions.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class IndividualBaselineLearningService {

    /** Redis key prefix of the per-livestock recalc throttle/mutex. */
    private static final String THROTTLE_KEY_PREFIX = "baseline-learning:recalc:";
    private static final String SOURCE_LEARNED = "LEARNED";

    private final BaselineLearningProperties properties;
    private final BaselineLearningCalculator calculator;
    private final BaselineLearningInputAssembler inputAssembler;
    private final HealthSnapshotRepository snapshotRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final TenantZoneResolver tenantZoneResolver;
    private final RedisCacheService redisCacheService;

    /**
     * Recalculate the individual baseline of one livestock.
     *
     * @param bypassThrottle true for manual/admin recalculations — skips the
     *                       Redis throttle+mutex (dev/ops compensation path)
     * @return the kernel result, or {@code null} when the livestock has no
     *         health snapshot yet or the run was throttled
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public BaselineLearningResult recalculate(Long livestockId, boolean bypassThrottle) {
        HealthSnapshot snapshot = snapshotRepo.findByLivestockId(livestockId).orElse(null);
        if (snapshot == null) {
            log.debug("Baseline learning skipped: no health snapshot for livestock {}", livestockId);
            return null;
        }

        if (!bypassThrottle && !acquireThrottle(livestockId)) {
            return null;
        }

        Instant asOf = Instant.now();
        // Farm → tenant → platform default timezone chain (ruling 2026-10-12);
        // zoneForFarm never returns null — unresolved chains fall back to UTC.
        ZoneId farmZone = tenantZoneResolver.zoneForFarm(snapshot.getFarmId(), null);

        Instant windowStart = asOf.minus(Duration.ofDays(properties.getWindowDays()));
        List<TemperatureLog> temperatures = tempLogRepo.findWindowByLivestockId(livestockId, windowStart, asOf);
        List<ActivityLog> activities = activityLogRepo.findWindowByLivestockId(livestockId, windowStart, asOf);

        BaselineLearningInput input = inputAssembler.assemble(livestockId, snapshot, asOf,
                properties.getWindowDays(), farmZone, temperatures, activities);
        BaselineLearningResult result = calculator.calculate(input);

        if (result.insufficientData()) {
            // Keep the previous baseline untouched — never fabricate evidence.
            // A learned baseline that no longer qualifies is stale: surface it
            // for operations, a DEFAULT cold start is the expected quiet path.
            if (SOURCE_LEARNED.equals(snapshot.getBaselineSource())) {
                log.warn("baseline stale for livestock {}: window no longer qualifies "
                                + "(admittedSamples={}, qualifiedDays={}); keeping learned baseline {}",
                        livestockId, result.admittedSampleCount(), result.qualifiedDays(),
                        result.baselineTemp());
            } else {
                log.debug("Baseline learning insufficient data for livestock {}: "
                                + "admittedSamples={}, qualifiedDays={}",
                        livestockId, result.admittedSampleCount(), result.qualifiedDays());
            }
            return result;
        }

        if (result.learnedNow() || SOURCE_LEARNED.equals(result.sourceAfterRun())) {
            persistLearnedBaseline(livestockId, result);
        }
        return result;
    }

    /**
     * Redis SET-NX throttle + mutex for one livestock. The key is
     * intentionally NOT released after the run: its TTL equals the minimum
     * recalc interval, so natural expiry doubles as the throttle window and a
     * crashed run can never leave a stuck lock behind. A Redis outage must
     * not block learning (tests and Redis-less installs): the failure is
     * logged and the run proceeds unthrottled.
     */
    private boolean acquireThrottle(Long livestockId) {
        try {
            return redisCacheService.setIfAbsent(
                    THROTTLE_KEY_PREFIX + livestockId, "1",
                    Duration.ofMinutes(properties.getMinRecalcIntervalMinutes()));
        } catch (Exception e) {
            log.warn("Baseline throttle unavailable for livestock {} — proceeding unthrottled: {}",
                    livestockId, e.getMessage());
            return true;
        }
    }

    /**
     * Persist a successful learning outcome through the targeted UPDATE.
     * Never a whole-entity save (see class javadoc); never a signal bump.
     */
    private void persistLearnedBaseline(Long livestockId, BaselineLearningResult result) {
        int updated = snapshotRepo.updateLearnedBaseline(
                new HealthSnapshotRepository.LearnedBaselineUpdate(
                        livestockId,
                        result.baselineTemp(),
                        result.admittedSampleCount(),
                        result.qualifiedDays(),
                        result.windowStart(),
                        result.windowEnd(),
                        result.bandLow(),
                        result.bandHigh(),
                        properties.getBaselineAlgorithmVersion()));
        if (updated == 0) {
            log.warn("Baseline learning update matched no snapshot row for livestock {}", livestockId);
            return;
        }
        log.info("Baseline learned for livestock {}: baseline={} band=[{},{}] samples={} qualifiedDays={} windowStart={}",
                livestockId, result.baselineTemp(), result.bandLow(), result.bandHigh(),
                result.admittedSampleCount(), result.qualifiedDays(), result.windowStart());
    }
}
