package com.smartlivestock.integration;

import com.smartlivestock.datagen.application.SimulationEvaluationService;
import com.smartlivestock.datagen.application.SimulationHerdGenerationService;
import com.smartlivestock.datagen.application.dto.SimulationDtos.PerHeadBaseline;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationEvaluationReport;
import com.smartlivestock.datagen.application.dto.SimulationDtos.SimulationHerdRunResult;
import com.smartlivestock.datagen.domain.service.SimulationHerdComposer.SimulationHerdParams;
import com.smartlivestock.health.application.dto.BaselineEvaluationDtos.BaselineEvaluationReport;
import com.smartlivestock.health.infrastructure.config.BaselineLearningProperties;
import com.smartlivestock.identity.application.TenantZoneResolver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * Simulation evaluation journey (plan 2026-11-05 Task 3, Testcontainers —
 * compile-only on machines without Docker; actual execution happens on the
 * remote testbed via
 * {@code scripts/remote-integration-test.sh --with-journey --target}).
 *
 * <p>End-to-end path: fixture livestock + capsule devices (raw JDBC, the
 * {@link IndividualBaselineLearningJourneyTest} pattern) → the generator
 * composes and persists a deterministic 3-head × 10-day herd (temperature/
 * activity rows source=DATAGEN, one SYNTHETIC ESTRUS label window, CONFIRMED
 * drinking_events for every composed bout — the detector replacement ring —
 * and the run registry two-table write) →
 * {@code BaselineLearningProperties.allowedSources} is widened with DATAGEN
 * in-process → {@code SimulationEvaluationService#evaluate} regenerates every
 * head's learned baseline (learning WRITE path, the deliberate deviation from
 * the plan's readOnly design) and reports learned-vs-truth metrics plus the
 * estrus episode/label alignment → the admin endpoint answers for the same
 * run and 404s for an unknown one → a second evaluation over the same run is
 * idempotent (no throw, shape intact).
 *
 * <p>Days = 10 (not the plan sketch's 3) on purpose: the learning kernel
 * demands {@code minQualifiedDays = 7} qualified days, so a 3-day window
 * could never produce a learned candidate and the central assertion (CLEAN
 * heads learn a non-null baseline) would be impossible.
 *
 * <p>The datagen synthesis tick runner is disabled for this context
 * ({@code datagen.enabled=false} via {@code @DynamicPropertySource}): the
 * V38 migration seeds a RUNNING synthesis scenario that would otherwise
 * ingest baseline telemetry (also source=DATAGEN) into the fixture livestock
 * between generation and evaluation and pollute the window reads.</p>
 */
public class SimulationEvaluationJourneyTest extends AbstractJourneyTest {

    private static final long FARM_ID = 1L;
    private static final long TENANT_ID = 1L;
    /** The farm wall clock both the generator phases and the learner's night
     *  window anchor to (dev-parity: the seeded tenant runs Asia/Shanghai). */
    private static final String FARM_TIMEZONE = "Asia/Shanghai";
    private static final long SEED = 42L;
    private static final int DAYS = 10;
    private static final int GRANULARITY_MINUTES = 30;
    private static final int POINTS_PER_DAY = 24 * 60 / GRANULARITY_MINUTES;
    private static final int HERD_SIZE = 3;
    /** 20% of 3 rounds to 1 — one ESTRUS head, the other two stay CLEAN. */
    private static final int EXPECTED_ESTRUS_HEADS = 1;
    private static final long OPERATOR_ID = 1L;
    private static final String EVALUATION_PATH = "/api/v1/admin/datagen/simulation/evaluation";

    @Autowired
    private SimulationHerdGenerationService generationService;

    @Autowired
    private SimulationEvaluationService evaluationService;

    @Autowired
    private BaselineLearningProperties baselineLearningProperties;

    @Autowired
    private TenantZoneResolver tenantZoneResolver;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private final List<Long> livestockIds = new ArrayList<>();
    private final List<Long> deviceIds = new ArrayList<>();
    private String originalTenantTimezone;
    private List<String> originalAllowedSources;
    private Long runId;

    /** Unique suffixes so repeated runs never collide with seed codes. */
    private static final AtomicLong CODE_SEQ = new AtomicLong(System.currentTimeMillis() % 1_000_000);

    @DynamicPropertySource
    static void disableSynthesisTick(DynamicPropertyRegistry registry) {
        // Kill the background synthesis tick (see class javadoc) — the
        // simulation generator itself is a plain service and stays active.
        registry.add("datagen.enabled", () -> "false");
    }

    @BeforeEach
    void setUpSimulation() {
        // Tenant timezone → the farm wall clock the generator anchors to: the
        // learning kernel's night window (farm-local hour ≥ 21 or < 6) then
        // covers exactly the generated local night (P4 peak 23:30 inside).
        // The resolver caches zones in-process, so evict after the raw JDBC
        // update.
        originalTenantTimezone = jdbcTemplate.queryForObject(
                "SELECT timezone FROM tenants WHERE id = ?", String.class, TENANT_ID);
        jdbcTemplate.update("UPDATE tenants SET timezone = ? WHERE id = ?", FARM_TIMEZONE, TENANT_ID);
        tenantZoneResolver.evictFarm(FARM_ID);
        tenantZoneResolver.evictTenant(TENANT_ID);

        // The generator writes source=DATAGEN rows; the learning kernel's
        // source whitelist must admit them for the journey. Restored after.
        originalAllowedSources = baselineLearningProperties.getAllowedSources();
        List<String> widened = new ArrayList<>(originalAllowedSources);
        if (!widened.contains("DATAGEN")) {
            widened.add("DATAGEN");
        }
        baselineLearningProperties.setAllowedSources(widened);

        // NO manual health_snapshots here: the generator provisions them
        // itself (ensureSnapshotExists) — the journey asserts on that below.
        for (int i = 0; i < HERD_SIZE; i++) {
            long[] ids = insertLivestockWithCapsule("SIM" + i);
            livestockIds.add(ids[0]);
            deviceIds.add(ids[1]);
        }
    }

    @AfterEach
    void tearDownSimulation() {
        if (originalAllowedSources != null) {
            baselineLearningProperties.setAllowedSources(originalAllowedSources);
        }
        // Children first, then bindings, then devices and livestock (FK order).
        if (!livestockIds.isEmpty()) {
            Object[] livestockArgs = livestockIds.toArray();
            String livestockIn = placeholders(livestockIds.size());
            jdbcTemplate.update("DELETE FROM temperature_logs WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM activity_logs WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM alerts WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM estrus_scores WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            // drinking_events carries device_id/livestock_id FKs — delete
            // before devices and livestock.
            jdbcTemplate.update("DELETE FROM drinking_events WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM ground_truth_labels WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM health_snapshots WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
        }
        if (runId != null) {
            jdbcTemplate.update("DELETE FROM simulation_truth_baselines WHERE run_id = ?", runId);
            jdbcTemplate.update("DELETE FROM simulation_runs WHERE id = ?", runId);
        }
        if (!deviceIds.isEmpty()) {
            jdbcTemplate.update("DELETE FROM installations WHERE device_id IN (" + placeholders(deviceIds.size()) + ")",
                    deviceIds.toArray());
            jdbcTemplate.update("DELETE FROM devices WHERE id IN (" + placeholders(deviceIds.size()) + ")",
                    deviceIds.toArray());
        }
        if (!livestockIds.isEmpty()) {
            jdbcTemplate.update("DELETE FROM livestock WHERE id IN (" + placeholders(livestockIds.size()) + ")",
                    livestockIds.toArray());
        }
        // Restore the shared tenant row and drop the resolver's cached zone.
        jdbcTemplate.update("UPDATE tenants SET timezone = ? WHERE id = ?",
                originalTenantTimezone, TENANT_ID);
        tenantZoneResolver.evictFarm(FARM_ID);
        tenantZoneResolver.evictTenant(TENANT_ID);
    }

    // ── Fixture helpers (IndividualBaselineLearningJourneyTest pattern) ──

    /** Minimal livestock + ACTIVE capsule device + open installation row. */
    private long[] insertLivestockWithCapsule(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "SIM-LIVE-" + tag + "-" + seq;
        String deviceCode = "SIM-DEV-" + tag + "-" + seq;

        jdbcTemplate.update(
                "INSERT INTO livestock (farm_id, livestock_code, breed, gender) VALUES (?, ?, 'OTHER', 'FEMALE')",
                FARM_ID, livestockCode);
        jdbcTemplate.update(
                "INSERT INTO devices (tenant_id, device_code, device_type, status) VALUES (?, ?, 'CAPSULE', 'ACTIVE')",
                TENANT_ID, deviceCode);
        Long livestockId = jdbcTemplate.queryForObject(
                "SELECT id FROM livestock WHERE livestock_code = ?", Long.class, livestockCode);
        Long deviceId = jdbcTemplate.queryForObject(
                "SELECT id FROM devices WHERE device_code = ?", Long.class, deviceCode);
        jdbcTemplate.update(
                "INSERT INTO installations (device_id, livestock_id, installed_at) VALUES (?, ?, NOW())",
                deviceId, livestockId);
        return new long[]{livestockId, deviceId};
    }

    private static String placeholders(int count) {
        return String.join(",", java.util.Collections.nCopies(count, "?"));
    }

    private List<Map<String, Object>> truthRows(Long runId) {
        return jdbcTemplate.queryForList(
                "SELECT livestock_id, true_baseline, herd_class FROM simulation_truth_baselines "
                        + "WHERE run_id = ? ORDER BY id", runId);
    }

    // ── The journey ──────────────────────────────────────────────

    @Test
    void simulationEvaluationJourney() {
        // 1) Generate the deterministic herd: 3 heads × 10 days × 48 points.
        SimulationHerdParams params = SimulationHerdParams.defaults(
                List.copyOf(livestockIds), List.copyOf(deviceIds), DAYS, GRANULARITY_MINUTES, SEED);
        SimulationHerdRunResult generated = generationService.generate(params, OPERATOR_ID);
        runId = generated.runId();
        assertThat(runId).isNotNull();

        long expectedRows = (long) HERD_SIZE * DAYS * POINTS_PER_DAY;
        assertThat(generated.temperatureRows()).isEqualTo(expectedRows);
        // No DETACHED head exists at this herd size (10% of 3 rounds to 0),
        // so every point carries an activity triple.
        assertThat(generated.activityRows()).isEqualTo(expectedRows);
        assertThat(generated.labelCounts()).hasSize(1);
        assertThat(generated.labelCounts()).containsEntry("ESTRUS", EXPECTED_ESTRUS_HEADS);
        assertThat(generated.truthBaselines()).hasSize(HERD_SIZE);

        // 2) The persistence contract holds row by row.
        String livestockIn = placeholders(HERD_SIZE);
        Long tempRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM temperature_logs WHERE livestock_id IN (" + livestockIn + ")",
                Long.class, livestockIds.toArray());
        assertThat(tempRows).isEqualTo(expectedRows);
        Long activityRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM activity_logs WHERE livestock_id IN (" + livestockIn + ")",
                Long.class, livestockIds.toArray());
        assertThat(activityRows).isEqualTo(expectedRows);

        Long labelRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ground_truth_labels WHERE livestock_id IN (" + livestockIn + ") "
                        + "AND source = 'SYNTHETIC'",
                Long.class, livestockIds.toArray());
        assertThat(labelRows).isEqualTo(1L);

        // Drinking-detector replacement ring: every composed bout is emitted
        // as a CONFIRMED drinking_events row the learner's exclusion consumes.
        // P7 Poisson(10) clamped to [3,14] bouts/animal/day over 10 days and
        // 3 heads bounds the total from below at 90.
        Long drinkingRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM drinking_events WHERE livestock_id IN (" + livestockIn + ")",
                Long.class, livestockIds.toArray());
        assertThat(drinkingRows).isGreaterThanOrEqualTo((long) HERD_SIZE * DAYS * 3);
        List<Map<String, Object>> drinkingSample = jdbcTemplate.queryForList(
                "SELECT device_id, event_start_at, event_end_at, temp_drop, min_temp, "
                        + "source, label, confidence, algorithm_version FROM drinking_events "
                        + "WHERE livestock_id IN (" + livestockIn + ")",
                livestockIds.toArray());
        assertThat(drinkingSample).isNotEmpty();
        assertThat(drinkingSample).allSatisfy(row -> {
            assertThat(row.get("source")).isEqualTo("DATAGEN");
            assertThat(row.get("label")).isEqualTo("CONFIRMED");
            assertThat(row.get("algorithm_version")).isEqualTo("V1");
            assertThat(new BigDecimal(row.get("confidence").toString()))
                    .isEqualByComparingTo(BigDecimal.ONE);
            assertThat(new BigDecimal(row.get("temp_drop").toString()))
                    .isBetween(new BigDecimal("2.30"), new BigDecimal("4.90"));
            assertThat(row.get("min_temp")).isNotNull();
            // [descent onset, trough) ordering per the learner's exclusion contract.
            assertThat(((java.sql.Timestamp) row.get("event_start_at")))
                    .isBefore((java.sql.Timestamp) row.get("event_end_at"));
        });

        List<Map<String, Object>> truths = truthRows(runId);
        assertThat(truths).hasSize(HERD_SIZE);
        // Deterministic quota: exactly one ESTRUS head, the rest CLEAN.
        assertThat(truths.stream().map(row -> row.get("herd_class")))
                .containsOnlyOnce("ESTRUS");

        // Generator-provisioned health snapshots: the learner skips heads
        // without one, so the generator must archive every head (review fix).
        Long snapshotRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM health_snapshots WHERE livestock_id IN (" + livestockIn + ")",
                Long.class, livestockIds.toArray());
        assertThat(snapshotRows).isEqualTo((long) HERD_SIZE);
        // True baselines sit inside the P1 truncated-normal range.
        assertThat(truths).allSatisfy(row -> assertThat(
                new BigDecimal(row.get("true_baseline").toString()))
                .isBetween(new BigDecimal("38.60"), new BigDecimal("39.50")));

        // 3) Evaluate: per-head learning WRITE + truth comparison.
        SimulationEvaluationReport report = evaluationService.evaluate(runId);

        assertThat(report.note()).isNotBlank();
        assertThat(report.runId()).isEqualTo(runId);
        assertThat(report.perHead()).hasSize(HERD_SIZE);
        assertThat(report.errorCount()).isZero();

        // Every per-head row mirrors the persisted truth.
        Map<Long, Map<String, Object>> truthById = truths.stream().collect(
                java.util.stream.Collectors.toMap(
                        row -> ((Number) row.get("livestock_id")).longValue(), row -> row));
        assertThat(report.perHead()).allSatisfy(head -> {
            Map<String, Object> truth = truthById.get(head.livestockId());
            assertThat(truth).as("truth row for livestock %s", head.livestockId()).isNotNull();
            assertThat(head.herdClass()).isEqualTo(truth.get("herd_class"));
            assertThat(head.trueBaseline())
                    .isEqualByComparingTo(new BigDecimal(truth.get("true_baseline").toString()));
            assertThat(head.evalStatus()).isEqualTo("OK");
        });

        // CLEAN heads learned a non-null baseline from the 10-day window
        // (the journey's reason for days=10 — see the class javadoc).
        List<PerHeadBaseline> cleanHeads = report.perHead().stream()
                .filter(head -> "CLEAN".equals(head.herdClass())).toList();
        assertThat(cleanHeads).hasSize(HERD_SIZE - EXPECTED_ESTRUS_HEADS);
        assertThat(cleanHeads).allSatisfy(head -> {
            assertThat(head.learnedBaseline()).isNotNull();
            assertThat(head.learnedSource()).isEqualTo("LEARNED");
            assertThat(head.absErr()).isNotNull();
            assertThat(head.manualProxyAbsErr()).isNotNull();
        });

        // Global metrics cover at least the CLEAN heads; each absErr column
        // stays inside the proxy clamp the manual-calibration band defines.
        assertThat(report.baselineMetrics().overall().count())
                .isGreaterThanOrEqualTo(HERD_SIZE - EXPECTED_ESTRUS_HEADS);
        assertThat(report.baselineMetrics().overall().mae()).isNotNull();
        assertThat(report.baselineMetrics().overall().manualMae()).isNotNull();

        // Mechanism comparison: the learned candidate (≈ μᵢ + night-diurnal
        // offset > 38.50) can only lower per-position scores, so its
        // high-score volume is monotonically bounded by the DEFAULT side.
        assertThat(report.estrusComparison().learnedSide()).isNotNull();
        assertThat(report.estrusComparison().learnedSide().highScorePoints())
                .isLessThanOrEqualTo(report.estrusComparison().defaultSide().highScorePoints());
        assertThat(report.estrusComparison().defaultSide().episodes())
                .isEqualTo(report.estrusComparison().defaultSide().tp()
                        + report.estrusComparison().defaultSide().fp());
        if (report.estrusComparison().defaultSide().episodes() > 0) {
            assertThat(report.estrusComparison().defaultSide().falseAlarmRate()).isBetween(0.0, 1.0);
        }

        // 4) Endpoint smoke: route + PLATFORM_ADMIN auth + serialization,
        //    and RESOURCE_NOT_FOUND for an unknown run.
        Map<String, Object> data = postApi(platformAdminToken, EVALUATION_PATH, Map.of("runId", runId));
        assertThat(extractId(data, "runId")).isEqualTo(String.valueOf(runId));
        assertThat((Object) data.get("note")).isNotNull();

        ResponseEntity<Map> miss = postRaw(platformAdminToken, EVALUATION_PATH,
                Map.of("runId", 9_999_999_999L));
        assertError(miss, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");

        // 5) Idempotency: a second evaluation over the same run must not
        //    throw and must keep the report shape (numeric values may drift
        //    with the sliding window — never hard-asserted here).
        SimulationEvaluationReport repeat = evaluationService.evaluate(runId);
        assertThat(repeat.note()).isNotBlank();
        assertThat(repeat.perHead()).hasSize(HERD_SIZE);
        List<PerHeadBaseline> cleanRepeat = repeat.perHead().stream()
                .filter(head -> "CLEAN".equals(head.herdClass())).toList();
        assertThat(cleanRepeat).allSatisfy(head -> assertThat(head.learnedBaseline()).isNotNull());
        assertThatCode(() -> evaluationService.evaluate(runId)).doesNotThrowAnyException();
    }
}
