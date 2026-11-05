package com.smartlivestock.datagen.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationHerdRunResult;
import com.smartlivestock.datagen.application.dto.SimulationDtos.TruthBaselineDto;
import com.smartlivestock.datagen.domain.model.GroundTruthLabel;
import com.smartlivestock.datagen.domain.model.LabelSource;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.repository.GroundTruthLabelRepository;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.HerdAnimal;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.LabelWindow;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SeriesPoint;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SimulationHerdParams;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SimulationHerdSeries;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.WaterBout;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * IO layer of the literature-parameterized herd simulator (plan 2026-11-05,
 * Task 2): composes deterministic series via the pure
 * {@link SimulationHerdComposer}, then persists temperature/activity rows
 * (source=DATAGEN), ground-truth labels (source=SYNTHETIC) and the run
 * registry (simulation_runs + simulation_truth_baselines, JdbcTemplate only —
 * the params JSONB column has no JPA entity mapping).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SimulationHerdGenerationService {

    private static final int MAX_HERD_SIZE = 200;
    private static final int MIN_DAYS = 3;
    private static final int MAX_DAYS = 30;
    private static final List<Integer> SUPPORTED_GRANULARITIES = List.of(10, 15, 30);
    private static final int BATCH_SIZE = 1000;
    private static final String DATAGEN_SOURCE = "DATAGEN";
    /**
     * Drinking-detector replacement ring: the composed valleys are emitted as
     * CONFIRMED events the baseline learner's drinking exclusion consumes —
     * standing in for a real F≈0.93 drinking detector's confirmed output.
     */
    private static final String DRINKING_LABEL_CONFIRMED = "CONFIRMED";
    /** Detector algorithm version stamped on the emitted event rows. */
    private static final String DRINKING_ALGORITHM_VERSION = "V1";
    /** temperature_logs.baseline_temp stays at the DEFAULT baseline (38.50) —
     *  the learner/replayer does not rely on the per-row baseline column. */
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    private final JdbcTemplate jdbcTemplate;
    private final GroundTruthLabelRepository groundTruthLabelRepository;
    private final ObjectMapper objectMapper;
    private final HealthSnapshotRepository snapshotRepository;
    private final SimulationHerdComposer composer = new SimulationHerdComposer();

    @Transactional
    public SimulationHerdRunResult generate(SimulationHerdParams params, Long operatorId) {
        validate(params);

        // asOf is captured once and passed into the pure composer — the
        // composer itself never reads the clock (determinism contract).
        Instant asOf = Instant.now();
        Instant windowStart = asOf.minus(Duration.ofDays(params.days()));

        SimulationHerdSeries series = composer.compose(params, asOf);

        long temperatureRows = 0;
        long activityRows = 0;
        long drinkingEventRows = 0;
        Map<String, Integer> labelCounts = new LinkedHashMap<>();
        List<TruthBaselineDto> truthBaselines = new ArrayList<>(series.animals().size());

        // Per-animal persistence; keep the 1:1 livestock/device pairing.
        for (int i = 0; i < series.animals().size(); i++) {
            HerdAnimal animal = series.animals().get(i);
            Long deviceId = params.deviceIds().get(i);

            temperatureRows += insertTemperatureRows(animal, deviceId);
            activityRows += insertActivityRows(animal, deviceId);
            drinkingEventRows += insertDrinkingEvents(animal, deviceId, params.seed());

            for (LabelWindow window : animal.labels()) {
                saveLabel(window, animal.livestockId(), params.seed());
                labelCounts.merge(window.type().name(), 1, Integer::sum);
            }
            truthBaselines.add(new TruthBaselineDto(
                    animal.livestockId(), animal.truthBaseline(), animal.herdClass().name()));
        }

        Long runId = insertRun(params, asOf, operatorId);
        insertTruthBaselines(runId, truthBaselines);
        ensureHealthSnapshots(params);

        log.info("Simulation run [{}] generated {} temperature rows / {} activity rows / "
                        + "{} drinking events for {} animals over {} days (seed={}, window [{}, {}))",
                runId, temperatureRows, activityRows, drinkingEventRows, series.animals().size(),
                params.days(), params.seed(), windowStart, asOf);

        return new SimulationHerdRunResult(runId, params.seed(), series.animals().size(),
                params.days(), temperatureRows, activityRows, labelCounts,
                truthBaselines, windowStart, asOf);
    }

    private void validate(SimulationHerdParams params) {
        if (params.livestockIds().isEmpty()
                || params.livestockIds().size() != params.deviceIds().size()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.simulationIdLists");
        }
        if (params.livestockIds().size() > MAX_HERD_SIZE) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.simulationHerdSize");
        }
        if (params.days() < MIN_DAYS || params.days() > MAX_DAYS) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.simulationDays");
        }
        if (!SUPPORTED_GRANULARITIES.contains(params.granularityMinutes())) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR, "error.datagen.simulationGranularity");
        }
    }

    // ------------------------------------------------------------------
    // Telemetry rows
    // ------------------------------------------------------------------

    private long insertTemperatureRows(HerdAnimal animal, Long deviceId) {
        String sql = "INSERT INTO temperature_logs "
                + "(livestock_id, device_id, temperature, baseline_temp, recorded_at, source) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        List<Object[]> batch = new ArrayList<>();
        long rows = 0;
        for (SeriesPoint point : animal.points()) {
            batch.add(new Object[]{
                    animal.livestockId(), deviceId, point.temperature(),
                    DEFAULT_BASELINE, Timestamp.from(point.recordedAt()), DATAGEN_SOURCE});
            if (batch.size() >= BATCH_SIZE) {
                rows += flush(sql, batch);
            }
        }
        rows += flush(sql, batch);
        return rows;
    }

    private long insertActivityRows(HerdAnimal animal, Long deviceId) {
        String sql = "INSERT INTO activity_logs "
                + "(livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at, source) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";
        List<Object[]> batch = new ArrayList<>();
        long rows = 0;
        for (SeriesPoint point : animal.points()) {
            // Detached stretches carry no activity triple — no row is written,
            // which is exactly how a detached sensor shows up in telemetry.
            if (point.activityIndex() == null) {
                continue;
            }
            batch.add(new Object[]{
                    animal.livestockId(), deviceId, point.stepCount(),
                    BigDecimal.valueOf(point.activityIndex()),
                    point.distanceMeters() == null ? null : BigDecimal.valueOf(point.distanceMeters()),
                    Timestamp.from(point.recordedAt()), DATAGEN_SOURCE});
            if (batch.size() >= BATCH_SIZE) {
                rows += flush(sql, batch);
            }
        }
        rows += flush(sql, batch);
        return rows;
    }

    /**
     * Emits one drinking_events row per composed bout — the replacement ring
     * for the drinking detector: a real F≈0.93 detector outputs confirmed
     * valley events from the telemetry series, and the baseline learner's
     * drinking exclusion consumes exactly this table. Without these rows the
     * learner absorbs the 2.3-4.9 °C valleys as ordinary samples and the
     * learned baseline collapses (remote journey evidence: −1.4 °C systematic
     * bias). Row semantics per the learner's contract
     * ({@code BaselineLearningInputAssembler.drinkingWindows}): the kernel
     * excludes [event_start_at, event_end_at] plus its own recovery window,
     * so {@code event_start_at} = descent onset, {@code event_end_at} =
     * trough; CONFIRMED label + confidence 1.0 model the detector having
     * flagged and a human having confirmed the event.
     */
    private long insertDrinkingEvents(HerdAnimal animal, Long deviceId, long seed) {
        if (animal.waterBouts().isEmpty()) {
            return 0;
        }
        String sql = "INSERT INTO drinking_events "
                + "(device_id, livestock_id, event_start_at, event_end_at, temp_drop, min_temp, "
                + "source, label, confidence, algorithm_version, note) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        List<Object[]> batch = new ArrayList<>(animal.waterBouts().size());
        long rows = 0;
        String note = "simulation run " + seed;
        for (WaterBout bout : animal.waterBouts()) {
            batch.add(new Object[]{
                    deviceId, animal.livestockId(),
                    Timestamp.from(bout.descentStartAt()), Timestamp.from(bout.valleyTime()),
                    BigDecimal.valueOf(bout.depth()).setScale(2, RoundingMode.HALF_UP),
                    bout.minTemp(),
                    DATAGEN_SOURCE, DRINKING_LABEL_CONFIRMED, BigDecimal.ONE,
                    DRINKING_ALGORITHM_VERSION, note});
            if (batch.size() >= BATCH_SIZE) {
                rows += flush(sql, batch);
            }
        }
        return rows + flush(sql, batch);
    }

    private long flush(String sql, List<Object[]> batch) {
        if (batch.isEmpty()) {
            return 0;
        }
        jdbcTemplate.batchUpdate(sql, batch);
        int size = batch.size();
        batch.clear();
        return size;
    }

    // ------------------------------------------------------------------
    // Ground-truth labels (source=SYNTHETIC, severity=0.8)
    // ------------------------------------------------------------------

    /**
     * Persists the label through the domain repository DIRECTLY — inside the
     * generation transaction on purpose (independent review P1-3). The former
     * {@code GroundTruthLabelService.saveLabel} runs REQUIRES_NEW and commits
     * immediately, so a later failure in the batch inserts would roll back the
     * telemetry while orphan labels survived. {@code labeledBy} stays null
     * (SYNTHETIC rows have no human labeler); {@code labeledAt} = now.
     */
    private void saveLabel(LabelWindow window, Long livestockId, long seed) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setType(toScenarioType(window.type()));
        label.setPeriodStart(window.start());
        label.setPeriodEnd(window.end());
        label.setSource(LabelSource.SYNTHETIC);
        label.setSeverity(0.8);
        label.setLabeledBy(null);
        label.setLabeledAt(Instant.now());
        label.setNote("simulation run " + seed);
        groundTruthLabelRepository.save(label);
    }

    private ScenarioType toScenarioType(LabelWindow.ScenarioTypeRef type) {
        return switch (type) {
            case ESTRUS -> ScenarioType.ESTRUS;
            case PREPARTUM -> ScenarioType.PREPARTUM;
            case ILLNESS -> ScenarioType.ILLNESS;
            case DETACHED -> ScenarioType.DETACHED;
        };
    }

    /**
     * Creates the health-snapshot row for every generated head
     * ({@code ON CONFLICT DO NOTHING} UPSERT). Product semantics: the
     * simulated telemetry is equivalent to real telemetry having landed —
     * and the real ingest path auto-provisions the snapshot — while this
     * direct-insert generator bypasses ingest, so without this step the
     * learner skips every head (recalculate returns null on missing
     * snapshot) and the whole evaluation collapses to insufficient.
     */
    private void ensureHealthSnapshots(SimulationHerdParams params) {
        String placeholders = String.join(",", java.util.Collections.nCopies(params.livestockIds().size(), "?"));
        Map<Long, Long> farmByLivestock = jdbcTemplate.query(
                "SELECT id, farm_id FROM livestock WHERE id IN (" + placeholders + ")",
                rs -> {
                    Map<Long, Long> byId = new LinkedHashMap<>();
                    while (rs.next()) {
                        byId.put(rs.getLong("id"), rs.getLong("farm_id"));
                    }
                    return byId;
                },
                params.livestockIds().toArray());
        for (Long livestockId : params.livestockIds()) {
            Long farmId = farmByLivestock.get(livestockId);
            if (farmId == null) {
                // FK guard: no livestock row → telemetry inserts would have
                // failed already; nothing to snapshot.
                log.warn("Simulation livestock {} has no livestock row — snapshot skipped", livestockId);
                continue;
            }
            snapshotRepository.ensureSnapshotExists(livestockId, farmId);
        }
    }

    // ------------------------------------------------------------------
    // Run registry
    // ------------------------------------------------------------------

    private Long insertRun(SimulationHerdParams params, Instant asOf, Long operatorId) {
        String paramsJson = serializeParams(params, asOf);
        // ?::jsonb cast — SimpleJdbcInsert cannot bind JSONB parameters.
        return jdbcTemplate.queryForObject(
                "INSERT INTO simulation_runs (seed, params, herd_size, days, created_by) "
                        + "VALUES (?, ?::jsonb, ?, ?, ?) RETURNING id",
                Long.class,
                params.seed(), paramsJson, params.livestockIds().size(), params.days(), operatorId);
    }

    private String serializeParams(SimulationHerdParams params, Instant asOf) {
        try {
            return objectMapper.writeValueAsString(new RunParams(params, asOf));
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "error.datagen.simulationParamsInvalid", new Object[]{e.getMessage()});
        }
    }

    private void insertTruthBaselines(Long runId, List<TruthBaselineDto> truthBaselines) {
        String sql = "INSERT INTO simulation_truth_baselines "
                + "(run_id, livestock_id, true_baseline, herd_class) VALUES (?, ?, ?, ?)";
        List<Object[]> batch = new ArrayList<>(truthBaselines.size());
        for (TruthBaselineDto baseline : truthBaselines) {
            batch.add(new Object[]{runId, baseline.livestockId(), baseline.trueBaseline(),
                    baseline.herdClass()});
        }
        jdbcTemplate.batchUpdate(sql, batch);
    }

    /** Replayable run inputs stored in simulation_runs.params (JSONB). */
    record RunParams(SimulationHerdParams params, Instant asOf) {
    }
}
