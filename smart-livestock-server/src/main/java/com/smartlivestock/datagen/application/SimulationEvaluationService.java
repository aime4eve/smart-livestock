package com.smartlivestock.datagen.application;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.datagen.application.dto.SimulationDtos.BaselineMetrics;
import com.smartlivestock.datagen.application.dto.SimulationDtos.BaselineStratum;
import com.smartlivestock.datagen.application.dto.SimulationDtos.EstrusComparison;
import com.smartlivestock.datagen.application.dto.SimulationDtos.EstrusSideResult;
import com.smartlivestock.datagen.application.dto.SimulationDtos.PerHeadBaseline;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationEvaluationReport;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.health.application.service.EstrusSeriesReplayer;
import com.smartlivestock.health.application.service.EstrusSeriesReplayer.EpisodeRecord;
import com.smartlivestock.health.application.service.IndividualBaselineLearningService;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
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
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.TimeZone;

/**
 * Evaluation of one literature-parameterized simulation run (plan 2026-11-05,
 * Task 3): for every animal of the run the learned baseline is REGENERATED
 * (recalculate with throttle bypass) and compared against the generator-known
 * truth, and the estrus mechanism is compared by replaying the telemetry
 * through the shared {@link EstrusSeriesReplayer} and aligning the ≥70 alert
 * episodes against the run's ESTRUS ground-truth label windows — once per
 * baseline candidate (DEFAULT 38.50 vs the learned value).
 *
 * <p><b>Deliberate deviation from the plan's readOnly design:</b> this service
 * carries NO {@code @Transactional(readOnly = true)}. The evaluation triggers
 * a per-head recalculate, which is a learning WRITE path ({@code REQUIRES_NEW}
 * — it persists the learned baseline into the health snapshot), while the
 * truth/replay comparison itself is read-only. The learned baseline must be
 * really persisted before it can be read back for the comparison, so a
 * read-only transaction wrapper is semantically wrong here, not just
 * unnecessary.</p>
 *
 * <p>Manual-calibration proxy: alongside the learned MAE each stratum carries
 * a proxy MAE computed from {@code true + ε} with ε ~ N(0, 0.2) truncated to
 * ±0.4 (the documented manual calibration error band, derived from the
 * research doc) — drawn deterministically from {@code Random(seed + 999)} in
 * truth-row order. The proxy is only aggregated over the same head set as the
 * learned metrics so the two columns stay comparable.</p>
 *
 * <p>Boundary: the report's {@code note} (MessageSource key
 * {@code simulation.evaluation.note}) always states that this is a mechanism
 * comparison and methodology validation on simulated data — never a real
 * false-positive rate (AGENTS §2 结论口径红线).</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SimulationEvaluationService {

    /** Fixed cold-start baseline — must stay aligned with the health
     *  pipeline's documented DEFAULT (same constant as
     *  {@code BaselineEvaluationService}). */
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    private static final String SOURCE_LEARNED = "LEARNED";
    private static final String EVAL_STATUS_OK = "OK";
    private static final String EVAL_STATUS_ERROR = "ERROR";

    /** Response disclaimer message key (AGENTS §4.1: no hardcoded user text). */
    static final String NOTE_KEY = "simulation.evaluation.note";

    private static final String SYNTHETIC_SOURCE = "SYNTHETIC";

    /** Manual-calibration proxy derivation: N(0, 0.2) truncated to ±0.4,
     *  seeded from the run seed so the proxy column is replayable. */
    private static final long MANUAL_PROXY_SEED_OFFSET = 999;
    private static final double MANUAL_PROXY_SIGMA = 0.2;
    private static final double MANUAL_PROXY_CLAMP = 0.4;

    /** Baseline hit-rate tolerances (°C). */
    private static final BigDecimal HIT_01 = new BigDecimal("0.10");
    private static final BigDecimal HIT_02 = new BigDecimal("0.20");

    /** Global stratum key of {@link BaselineMetrics#overall()}. */
    private static final String OVERALL_KEY = "ALL";

    /** Hibernate persists Instant as UTC wall-clock into timestamp columns;
     *  raw JDBC reads must use the same calendar to round-trip exactly. */
    private static final TimeZone UTC = TimeZone.getTimeZone("UTC");

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;
    private final IndividualBaselineLearningService learningService;
    private final HealthSnapshotRepository snapshotRepo;
    private final TemperatureLogRepository tempLogRepo;
    private final ActivityLogRepository activityLogRepo;
    private final EstrusSeriesReplayer replayer;
    private final MessageResolver messageResolver;

    private record RunRecord(long seed, int days, String paramsJson) {
    }

    private record TruthRow(Long livestockId, BigDecimal trueBaseline, String herdClass) {
    }

    /** ESTRUS label window of one head (inclusive endpoints, matching
     *  {@code GroundTruthLabel.overlaps}). */
    private record LabelInterval(Instant start, Instant end) {
        boolean overlaps(EpisodeRecord episode) {
            return !episode.end().isBefore(start) && !episode.start().isAfter(end);
        }
    }

    /** Per-head deterministic manual-proxy draw: N(0, 0.2) truncated to ±0.4. */
    private BigDecimal drawManualProxyEpsilon(Random rng) {
        for (int attempt = 0; attempt < 1000; attempt++) {
            double value = rng.nextGaussian() * MANUAL_PROXY_SIGMA;
            if (Math.abs(value) <= MANUAL_PROXY_CLAMP) {
                return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP);
            }
        }
        // Rejection sampling keeps the draw sequence identical across runs;
        // a 1000-fold consecutive miss is statistically unreachable.
        return BigDecimal.ZERO.setScale(2);
    }

    /**
     * Evaluate one simulation run end to end. Never wrapped in a transaction:
     * each head's recalculate commits independently ({@code REQUIRES_NEW}) and
     * every read below runs in autocommit — see the class javadoc for why the
     * plan's readOnly design was intentionally dropped.
     */
    public SimulationEvaluationReport evaluate(long runId) {
        Instant evaluatedAt = Instant.now();
        RunRecord run = loadRun(runId);
        Instant asOf = parseAsOf(run.paramsJson());
        Instant windowStart = asOf.minus(Duration.ofDays(run.days()));

        List<TruthRow> truths = loadTruthRows(runId);
        Map<Long, List<LabelInterval>> estrusLabels = loadEstrusLabels(
                truths.stream().map(TruthRow::livestockId).toList(), windowStart, asOf);

        Random proxyRng = new Random(run.seed() + MANUAL_PROXY_SEED_OFFSET);

        List<PerHeadBaseline> perHead = new ArrayList<>(truths.size());
        Map<String, StratumAccumulator> strata = new LinkedHashMap<>();
        StratumAccumulator overall = new StratumAccumulator();
        int insufficientCount = 0;
        int errorCount = 0;

        EstrusTotals defaultTotals = new EstrusTotals();
        EstrusTotals learnedTotals = new EstrusTotals();

        for (TruthRow truth : truths) {
            String evalStatus = EVAL_STATUS_OK;
            try {
                learningService.recalculate(truth.livestockId(), true);
            } catch (Exception e) {
                // One bad head must not stop the run — flag it and move on.
                log.warn("Simulation evaluation recalculate failed for livestock {} (run {}): {}",
                        truth.livestockId(), runId, e.getMessage());
                evalStatus = EVAL_STATUS_ERROR;
                errorCount++;
            }

            // Read the learned value back from the snapshot: applyLearned does
            // not gate the read — the value must be really persisted to count.
            HealthSnapshot snapshot = snapshotRepo.findByLivestockId(truth.livestockId()).orElse(null);
            String learnedSource = snapshot != null && snapshot.getBaselineSource() != null
                    ? snapshot.getBaselineSource() : null;
            BigDecimal learned = null;
            if (snapshot != null && SOURCE_LEARNED.equals(snapshot.getBaselineSource())
                    && snapshot.getBaselineTemp() != null) {
                learned = snapshot.getBaselineTemp();
                learnedSource = SOURCE_LEARNED;
            } else if (evalStatus.equals(EVAL_STATUS_OK)) {
                // DEFAULT / insufficient / no snapshot: the head carries no
                // learned candidate — counted as insufficient, never fabricated.
                insufficientCount++;
            }

            BigDecimal epsilon = drawManualProxyEpsilon(proxyRng);
            Double absErr = null;
            Double manualProxyAbsErr = null;
            if (evalStatus.equals(EVAL_STATUS_OK) && learned != null) {
                BigDecimal err = learned.subtract(truth.trueBaseline());
                absErr = err.abs().doubleValue();
                manualProxyAbsErr = epsilon.abs().doubleValue();
                strata.computeIfAbsent(truth.herdClass(), key -> new StratumAccumulator())
                        .add(err, epsilon.abs());
                overall.add(err, epsilon.abs());
            }
            perHead.add(new PerHeadBaseline(truth.livestockId(), truth.herdClass(),
                    truth.trueBaseline(), learned, learnedSource, absErr, manualProxyAbsErr, evalStatus));

            // Mechanism comparison: replay the generated window under both
            // candidates and align the ≥70 episodes against the ESTRUS labels.
            List<TemperatureLog> temperatures = tempLogRepo.findWindowByLivestockId(
                    truth.livestockId(), windowStart, asOf);
            List<ActivityLog> activities = activityLogRepo.findWindowByLivestockId(
                    truth.livestockId(), windowStart, asOf);
            List<LabelInterval> labels = estrusLabels.getOrDefault(truth.livestockId(), List.of());
            EstrusSeriesReplayer.ReplayResult replay = replayer.replay(truth.livestockId(),
                    temperatures, activities, DEFAULT_BASELINE, learned);

            defaultTotals.add(replay.defaultSide(), labels);
            if (replay.learnedSide() != null) {
                learnedTotals.add(replay.learnedSide(), labels);
            }
        }

        List<BaselineStratum> byHerdClass = new ArrayList<>(strata.size());
        strata.forEach((herdClass, acc) -> byHerdClass.add(acc.toStratum(herdClass)));

        return new SimulationEvaluationReport(runId, evaluatedAt, perHead,
                new BaselineMetrics(overall.toStratum(OVERALL_KEY), byHerdClass),
                new EstrusComparison(defaultTotals.toSideResult(), learnedTotals.toSideResult()),
                insufficientCount, errorCount,
                messageResolver.resolve(NOTE_KEY, null, LocaleContextHolder.getLocale()));
    }

    // ------------------------------------------------------------------
    // Run / truth / label reads
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
                "SELECT livestock_id, true_baseline, herd_class "
                        + "FROM simulation_truth_baselines WHERE run_id = ? ORDER BY id",
                (rs, rowNum) -> new TruthRow(rs.getLong("livestock_id"),
                        rs.getBigDecimal("true_baseline"), rs.getString("herd_class")),
                runId);
    }

    /**
     * ESTRUS label windows of the run's animals (SYNTHETIC source only),
     * constrained to the run's generation window: without the period filter a
     * historical SYNTHETIC label on the same livestock (an earlier simulation
     * run or synthesis tick) would be miscounted as an FN of this run.
     */
    private Map<Long, List<LabelInterval>> loadEstrusLabels(List<Long> livestockIds,
                                                            Instant evalStart, Instant evalEnd) {
        if (livestockIds.isEmpty()) {
            return Map.of();
        }
        String placeholders = String.join(",", java.util.Collections.nCopies(livestockIds.size(), "?"));
        Object[] ids = livestockIds.toArray();
        Object[] args = new Object[ids.length + 4];
        args[0] = ScenarioType.ESTRUS.getDbValue();
        args[1] = SYNTHETIC_SOURCE;
        args[2] = Timestamp.from(evalEnd);     // period_start < evalEnd
        args[3] = Timestamp.from(evalStart);   // period_end > evalStart
        System.arraycopy(ids, 0, args, 4, ids.length);
        return jdbcTemplate.query(
                "SELECT livestock_id, period_start, period_end FROM ground_truth_labels "
                        + "WHERE type = ? AND source = ? AND period_start < ? AND period_end > ? "
                        + "AND livestock_id IN (" + placeholders + ")",
                rs -> {
                    Map<Long, List<LabelInterval>> byHead = new LinkedHashMap<>();
                    while (rs.next()) {
                        byHead.computeIfAbsent(rs.getLong("livestock_id"), key -> new ArrayList<>())
                                .add(new LabelInterval(utcTimestamp(rs, "period_start"),
                                        utcTimestamp(rs, "period_end")));
                    }
                    return byHead;
                },
                args);
    }

    /**
     * Read a timestamp column with the UTC calendar Hibernate writes with.
     * Premise: the container JVM runs with {@code -Duser.timezone=UTC}
     * (pinned in docker-compose dev/test), matching the UTC calendar here.
     */
    private static Instant utcTimestamp(ResultSet rs, String column) throws SQLException {
        return rs.getTimestamp(column, Calendar.getInstance(UTC)).toInstant();
    }

    // ------------------------------------------------------------------
    // Aggregation
    // ------------------------------------------------------------------

    /** Baseline metric accumulator for one stratum (global or herd-class). */
    private static final class StratumAccumulator {
        private int count;
        private double sumAbsErr;
        private double sumSignedErr;
        private int hit01Count;
        private int hit02Count;
        private double sumManualAbsErr;

        void add(BigDecimal signedErr, BigDecimal manualAbsErr) {
            count++;
            sumAbsErr += signedErr.abs().doubleValue();
            sumSignedErr += signedErr.doubleValue();
            if (signedErr.abs().compareTo(HIT_01) <= 0) {
                hit01Count++;
            }
            if (signedErr.abs().compareTo(HIT_02) <= 0) {
                hit02Count++;
            }
            sumManualAbsErr += manualAbsErr.doubleValue();
        }

        BaselineStratum toStratum(String herdClass) {
            if (count == 0) {
                return new BaselineStratum(herdClass, 0, null, null, null, null, null);
            }
            return new BaselineStratum(herdClass, count,
                    round4(sumAbsErr / count), round4(sumSignedErr / count),
                    round4((double) hit01Count / count), round4((double) hit02Count / count),
                    round4(sumManualAbsErr / count));
        }
    }

    /** Estrus-side accumulator across the run's heads. */
    private static final class EstrusTotals {
        private int episodes;
        private int highScorePoints;
        private int tp;
        private int fp;
        private int fn;

        void add(EstrusSeriesReplayer.SideResult side, List<LabelInterval> labels) {
            episodes += side.episodes().size();
            highScorePoints += side.highScorePoints();
            boolean[] covered = new boolean[labels.size()];
            for (EpisodeRecord episode : side.episodes()) {
                boolean hit = false;
                for (int i = 0; i < labels.size(); i++) {
                    if (labels.get(i).overlaps(episode)) {
                        hit = true;
                        covered[i] = true;
                    }
                }
                if (hit) {
                    tp++;
                } else {
                    fp++;
                }
            }
            for (boolean labelCovered : covered) {
                if (!labelCovered) {
                    fn++;
                }
            }
        }

        EstrusSideResult toSideResult() {
            Double falseAlarmRate = (tp + fp) == 0 ? null : round4((double) fp / (tp + fp));
            return new EstrusSideResult(episodes, highScorePoints, tp, fp, fn, falseAlarmRate);
        }
    }

    /** Four-decimal rounding for aggregate metrics (JSON-friendly doubles). */
    private static Double round4(double value) {
        return BigDecimal.valueOf(value).setScale(4, RoundingMode.HALF_UP).doubleValue();
    }
}
