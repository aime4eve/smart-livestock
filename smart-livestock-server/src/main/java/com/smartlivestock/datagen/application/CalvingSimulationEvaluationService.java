package com.smartlivestock.datagen.application;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.datagen.application.dto.SimulationDtos.CalvingEvaluationReport;
import com.smartlivestock.datagen.application.dto.SimulationDtos.ChannelAvailability;
import com.smartlivestock.datagen.application.dto.SimulationDtos.PerHeadCalving;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.AlertEpisode;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.CalvingReplayResult;
import com.smartlivestock.health.application.service.CalvingSeriesReplayer.ScorePoint;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ActivitySample;
import com.smartlivestock.health.domain.service.CalvingPredictionService.ExclusionWindow;
import com.smartlivestock.health.domain.service.CalvingPredictionService.TempSample;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.MessageResolver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Calving-detection evaluation of one literature-parameterized simulation run
 * (NIX-381 Task 4, plan 2026-11-06 "仿真评估管道" + Task 2c review: dual-scenario
 * design). Parallel to {@link SimulationEvaluationService} — the existing
 * estrus/baseline evaluation logic is untouched.
 *
 * <p>Per head of the run (manifest = {@code simulation_truth_baselines} rows,
 * same JdbcTemplate loader caliber): load the run-window telemetry and the
 * raw drinking-event windows, replay through the shared
 * {@link CalvingSeriesReplayer} (production kernel + shared alert state
 * machine, poll-grid cadence, event-time visibility), then align the alert
 * episodes against the ground truth:</p>
 * <ul>
 *   <li><b>Detection</b>: a PREPARTUM head is detected (TP) when an episode
 *       raised at/before the ground-truth calving instant (= the PREPARTUM
 *       label's {@code period_end}); lead = calving − raiseAt (the LATEST
 *       qualifying raise — the alert state at calving). Otherwise missed (FN).</li>
 *   <li><b>False alarms</b>: every episode of a non-PREPARTUM head
 *       (CLEAN/WATER/FEVER/ESTRUS/DETACHED), episode caliber.</li>
 *   <li><b>Channel availability</b>: temperature-channel usable grid points
 *       per herd-class group (review 2b/2d: exclusion-dark days are structural,
 *       so the reports must carry availability per class).</li>
 *   <li><b>Rebound hit rate</b>: rebound-flagged grid points over all grid
 *       points of non-PREPARTUM heads — the pipeline generates no rebound
 *       shape (open question 5), so this rate must stay near zero; a nonzero
 *       rate measures the false-positive side of the rebound component. With
 *       the rebound switch off (the default since plan 7d) the kernel flags
 *       nothing and the rate reads 0 by construction.</li>
 * </ul>
 *
 * <p><b>Dual scenario</b> (Task 2c review): {@code withBreedingPrior=false}
 * (scenario A) replays without any gestation prior — the conservative basis
 * the acceptance thresholds apply to. {@code withBreedingPrior=true}
 * (scenario B) synthesizes the breeding date backwards from the ground-truth
 * calving ({@code period_end − gestationDays}) — the "record available"
 * scenario. Those numbers are NOT a prediction ability (simulation red line);
 * the report note carries the boundary.</p>
 *
 * <p>Read-only: no learning write path is triggered (unlike
 * {@link SimulationEvaluationService}), and the method intentionally carries
 * no transaction wrapper — every read runs in autocommit, exactly like the
 * existing evaluation endpoint's semantics.</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CalvingSimulationEvaluationService {

    /** Same simulated-data disclaimer key as the estrus evaluation (AGENTS §4.1). */
    static final String NOTE_KEY = "simulation.evaluation.note";

    /** Herd class marking a prepartum animal (simulation_truth_baselines.herd_class). */
    static final String HERD_CLASS_PREPARTUM = SimulationHerdComposer.HerdClass.PREPARTUM.name();

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;
    private final TemperatureLogRepository tempLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final DrinkingEventJpaRepository drinkingEventJpaRepository;
    private final GroundTruthLabelRepository groundTruthLabelRepository;
    private final CalvingSeriesReplayer replayer;
    private final CalvingPredictionProperties properties;
    private final MessageResolver messageResolver;

    private record RunRecord(long seed, int days, String paramsJson) {
    }

    private record TruthRow(Long livestockId, String herdClass) {
    }

    /** One replayed head plus its ground-truth calving instant (null = none). */
    public record HeadOutcome(Long livestockId, String herdClass, Instant calvingAt, CalvingReplayResult replay) {
    }

    /**
     * Evaluate one simulation run for one scenario. Never wrapped in a
     * transaction — the whole pass is read-only.
     */
    public CalvingEvaluationReport evaluate(long runId, boolean withBreedingPrior) {
        Instant evaluatedAt = Instant.now();
        RunRecord run = loadRun(runId);
        Instant asOf = parseAsOf(run.paramsJson());
        Instant windowStart = asOf.minus(Duration.ofDays(run.days()));

        List<TruthRow> truths = loadTruthRows(runId);
        Duration buffer = Duration.ofMinutes(properties.getDrinkingExclusionBufferMinutes());

        List<HeadOutcome> heads = new ArrayList<>(truths.size());
        for (TruthRow truth : truths) {
            Instant calvingAt = loadPrepartumCalvingAt(truth.livestockId(), windowStart, asOf);
            List<TempSample> temps = tempLogRepo.findWindowByLivestockId(truth.livestockId(), windowStart, asOf)
                    .stream().map(t -> new TempSample(t.getRecordedAt(), t.getTemperature()))
                    .toList();
            List<ActivitySample> acts = activityLogRepo.findWindowByLivestockId(truth.livestockId(), windowStart, asOf)
                    .stream().map(a -> new ActivitySample(a.getRecordedAt(), a.getActivityIndex()))
                    .toList();
            // Raw event windows — the replayer applies the production buffer rule.
            List<ExclusionWindow> drinking = drinkingEventJpaRepository
                    .findByLivestockIdAndEventStartAtLessThanAndEventEndAtGreaterThanEqual(
                            truth.livestockId(), asOf, windowStart.minus(buffer))
                    .stream().map(event -> new ExclusionWindow(event.getEventStartAt(), event.getEventEndAt()))
                    .toList();
            Instant breedingAt = syntheticBreedingAt(calvingAt, withBreedingPrior, properties);

            CalvingReplayResult replay = replayer.replay(truth.livestockId(), temps, acts, drinking,
                    breedingAt, asOf);
            heads.add(new HeadOutcome(truth.livestockId(), truth.herdClass(), calvingAt, replay));
        }

        return assembleReport(runId, evaluatedAt, withBreedingPrior, heads,
                messageResolver.resolve(NOTE_KEY, null, LocaleContextHolder.getLocale()));
    }

    // ------------------------------------------------------------------
    // Pure metric assembly (unit-tested without IO)
    // ------------------------------------------------------------------

    /**
     * Pure alignment of replay outcomes against ground truth — no I/O, no
     * clock. Metric definitions are in the class javadoc; PREPARTUM heads
     * without a known calving instant are unjudgeable (counted neither as
     * detected nor missed, but surfaced via perHead with calvingAt null).
     */
    static CalvingEvaluationReport assembleReport(long runId, Instant evaluatedAt, boolean withBreedingPrior,
                                                  List<HeadOutcome> heads, String note) {
        int detected = 0;
        int missed = 0;
        List<Double> leads = new ArrayList<>();
        int falseAlarmEpisodes = 0;
        int prepartumAvailable = 0;
        int prepartumTotal = 0;
        int nonPrepartumAvailable = 0;
        int nonPrepartumTotal = 0;
        long reboundPointsNonPrepartum = 0;
        List<PerHeadCalving> perHead = new ArrayList<>(heads.size());

        for (HeadOutcome head : heads) {
            boolean prepartum = HERD_CLASS_PREPARTUM.equals(head.herdClass());
            CalvingReplayResult replay = head.replay();

            if (prepartum) {
                prepartumAvailable += replay.tempChannelAvailablePoints();
                prepartumTotal += replay.totalPoints();
            } else {
                nonPrepartumAvailable += replay.tempChannelAvailablePoints();
                nonPrepartumTotal += replay.totalPoints();
                reboundPointsNonPrepartum += replay.points().stream().filter(ScorePoint::reboundDetected).count();
                // Episode caliber: every episode of a non-PREPARTUM head is a false alarm.
                falseAlarmEpisodes += replay.episodes().size();
            }

            // Detection: the LATEST episode raise at/before the calving instant
            // (the alert state at calving), not an earlier unrelated episode.
            Instant detectionRaise = null;
            if (head.calvingAt() != null) {
                for (AlertEpisode episode : replay.episodes()) {
                    if (!episode.raiseAt().isAfter(head.calvingAt())
                            && (detectionRaise == null || episode.raiseAt().isAfter(detectionRaise))) {
                        detectionRaise = episode.raiseAt();
                    }
                }
            }
            Double leadHours = detectionRaise == null ? null
                    : hours(Duration.between(detectionRaise, head.calvingAt()));
            if (prepartum && head.calvingAt() != null) {
                if (detectionRaise != null) {
                    detected++;
                    leads.add(leadHours);
                } else {
                    missed++;
                }
            }

            perHead.add(new PerHeadCalving(head.livestockId(), head.herdClass(), detectionRaise,
                    head.calvingAt(), leadHours, replay.episodes().size(),
                    ratio(replay.tempChannelAvailablePoints(), replay.totalPoints())));
        }

        return new CalvingEvaluationReport(runId, evaluatedAt, withBreedingPrior,
                detected, missed,
                leads.isEmpty() ? null : Collections.min(leads),
                leads.isEmpty() ? null : median(leads),
                leads.isEmpty() ? null : Collections.max(leads),
                falseAlarmEpisodes,
                new ChannelAvailability(prepartumAvailable, prepartumTotal,
                        nonPrepartumAvailable, nonPrepartumTotal),
                nonPrepartumTotal == 0 ? null : round4((double) reboundPointsNonPrepartum / nonPrepartumTotal),
                List.copyOf(perHead),
                note);
    }

    /**
     * Scenario B synthesis: breeding = ground-truth calving − nominal
     * gestation. Null for scenario A or a head without a known calving
     * instant (the prior stays neutral there — a CLEAN/WATER/... head never
     * carries a usable record in this evaluation).
     */
    static Instant syntheticBreedingAt(Instant calvingAtOrNull, boolean withBreedingPrior,
                                       CalvingPredictionProperties p) {
        if (!withBreedingPrior || calvingAtOrNull == null) {
            return null;
        }
        return calvingAtOrNull.minus(Duration.ofDays(p.getGestationDays()));
    }

    /** Lead in hours, two decimals (grid-aligned raises vs 30-min-granular truth). */
    private static Double hours(Duration lead) {
        return BigDecimal.valueOf(lead.getSeconds())
                .divide(BigDecimal.valueOf(3600), 2, RoundingMode.HALF_UP)
                .doubleValue();
    }

    /** Standard median: middle value, or the mean of the two middle values. */
    private static Double median(List<Double> values) {
        List<Double> sorted = new ArrayList<>(values);
        Collections.sort(sorted);
        int size = sorted.size();
        if (size % 2 == 1) {
            return sorted.get(size / 2);
        }
        return round4((sorted.get(size / 2 - 1) + sorted.get(size / 2)) / 2);
    }

    private static Double ratio(int available, int total) {
        return total == 0 ? null : round4((double) available / total);
    }

    /** Four-decimal rounding for aggregate metrics (JSON-friendly doubles). */
    private static Double round4(double value) {
        return BigDecimal.valueOf(value).setScale(4, RoundingMode.HALF_UP).doubleValue();
    }

    // ------------------------------------------------------------------
    // Run / truth / label reads (same JdbcTemplate loader caliber as
    // SimulationEvaluationService — copied, not shared, to leave the
    // existing evaluation untouched)
    // ------------------------------------------------------------------

    private RunRecord loadRun(long runId) {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT seed, days, params::text AS params FROM simulation_runs WHERE id = ?", runId);
        if (rows.isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                    "error.datagen.simulationRunNotFound", new Object[]{runId});
        }
        Map<String, Object> row = rows.get(0);
        return new RunRecord(((Number) row.get("seed")).longValue(),
                ((Number) row.get("days")).intValue(),
                (String) row.get("params"));
    }

    /** The run's generation instant comes back from the persisted params JSONB. */
    private Instant parseAsOf(String paramsJson) {
        try {
            JsonNode asOf = objectMapper.readTree(paramsJson).path("asOf");
            if (asOf.isTextual()) {
                return Instant.parse(asOf.asText());
            }
            if (asOf.isNumber()) {
                return Instant.ofEpochMilli(asOf.asLong());
            }
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "error.datagen.simulationParamsInvalid", new Object[]{e.getMessage()});
        }
        throw new ApiException(ErrorCode.INTERNAL_ERROR,
                "error.datagen.simulationParamsInvalid", new Object[]{"missing asOf"});
    }

    private List<TruthRow> loadTruthRows(long runId) {
        return jdbcTemplate.query(
                "SELECT livestock_id, herd_class FROM simulation_truth_baselines WHERE run_id = ? ORDER BY id",
                (rs, rowNum) -> new TruthRow(rs.getLong("livestock_id"), rs.getString("herd_class")),
                runId);
    }

    /**
     * Ground-truth calving instant of one head: the {@code period_end} of the
     * PREPARTUM label overlapping the run window (the herd composer writes
     * {@code [calving − 48h, calving]}). The window constraint mirrors
     * {@code SimulationEvaluationService.loadEstrusLabels}: without it a
     * historical label from an earlier run would be misattributed. The latest
     * matching label wins (one per head by construction).
     */
    private Instant loadPrepartumCalvingAt(Long livestockId, Instant from, Instant to) {
        return groundTruthLabelRepository.findByLivestockIdAndPeriodOverlap(livestockId, from, to).stream()
                .filter(label -> label != null && label.getType() == ScenarioType.PREPARTUM)
                .map(GroundTruthLabel::getPeriodEnd)
                .filter(Objects::nonNull)
                .max(Instant::compareTo)
                .orElse(null);
    }
}
