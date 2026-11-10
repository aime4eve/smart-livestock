package com.smartlivestock.integration;

import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.health.infrastructure.config.EstrusScoringProperties;
import com.smartlivestock.health.infrastructure.persistence.entity.ActivityLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.ActivityLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import com.smartlivestock.iot.domain.model.DeviceType;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * Estrus score explanation journey (NIX-390 Task 2, Testcontainers —
 * compile-only on machines without Docker; actual execution happens on the
 * remote testbed via
 * {@code scripts/remote-integration-test.sh --with-journey --target}).
 *
 * <p>Proves the extended {@code GET /farms/{farmId}/health/estrus/{livestockId}}
 * detail payload end-to-end against a fresh Flyway-migrated database:</p>
 * <ol>
 *   <li>a row inserted WITHOUT {@code feature_version} lands on the migration
 *       default {@code 'LEGACY'} and the endpoint explains it with the legacy
 *       fixed-weight breakdown (the dev-measured anchor 88 / 0.18 / 40.30 →
 *       35.2 / 9.0 / 1.209, weights 0.4/0.3/0.3, weighted sum 17.1427 → 17);</li>
 *   <li>a NORMALIZED row produced by the real {@code processTelemetry} chain
 *       (fixture of {@link EstrusNormalizedScoringJourneyTest}, distance
 *       channel included) explains with ratio 3.00, components 100/42/100,
 *       weights 0.4/0.3/0.3, distanceParticipated=true, distanceRatio 3.000;</li>
 *   <li>the CAPSULE-only variant (no distance channel) explains with
 *       renormalized weights 4/7 and 3/7, distanceParticipated=false,
 *       distanceScore 0 / weight 0;</li>
 *   <li>a livestock with no score row at all keeps the existing empty-state
 *       shape (score 0, empty trend) with every explanation field null.</li>
 * </ol>
 *
 * <p><b>Fixture arithmetic</b> is identical to
 * {@link EstrusNormalizedScoringJourneyTest} (30-minute cadence, 3 same-phase
 * 24h-apart baseline windows + one current window): activity mean 180 vs
 * baseline 60 → ratio 3.0 → ladder 100; anchor temp 39.05 over 38.50 →
 * Δ0.55 → 42; distance 1500 vs 500 → ratio 3.0 → 100; full row score 83,
 * CAPSULE-only (distance absent) (100·0.4 + 42·0.3)/0.7 → 75.</p>
 */
public class EstrusExplanationJourneyTest extends AbstractJourneyTest {

    private static final long FARM_ID = 1L;
    private static final long TENANT_ID = 1L;
    private static final String SOURCE = "MANUAL_IMPORT";
    private static final int GRANULARITY_MINUTES = 30;
    private static final int FRAMES_PER_WINDOW = 12;
    private static final int BASELINE_WINDOW_COUNT = 3;
    private static final long BASELINE_OFFSET_HOURS = 24;

    private static final BigDecimal BASELINE_ACTIVITY = new BigDecimal("60");
    private static final BigDecimal CURRENT_ACTIVITY = new BigDecimal("180");
    private static final Integer BASELINE_STEP_COUNT = 200;
    private static final Integer CURRENT_STEP_COUNT = 600;
    private static final BigDecimal BASELINE_DISTANCE = new BigDecimal("500.00");
    private static final BigDecimal CURRENT_DISTANCE = new BigDecimal("1500.00");
    private static final BigDecimal BASELINE_TEMP = new BigDecimal("38.50");
    private static final BigDecimal ANCHOR_TEMP = new BigDecimal("39.05");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    @Autowired
    private HealthApplicationService healthApplicationService;

    @Autowired
    private EstrusScoringProperties estrusScoringProperties;

    @Autowired
    private ActivityLogJpaRepository activityLogRepository;

    @Autowired
    private TemperatureLogJpaRepository temperatureLogRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /** Fixed anchor: the whole fixture is defined by exact offsets from this instant. */
    private Instant anchor;

    private final List<Long> livestockIds = new ArrayList<>();
    private final List<Long> deviceIds = new ArrayList<>();

    /** Shared-singleton guards: whatever the suite entered with is restored after. */
    private String originalMode;
    private int originalMaxWindowRows;

    /** Unique suffixes so repeated runs never collide with seed codes. */
    private static final AtomicLong CODE_SEQ = new AtomicLong(System.currentTimeMillis() % 1_000_000);

    @BeforeEach
    void setUpExplanationJourney() {
        anchor = Instant.now().truncatedTo(ChronoUnit.HOURS);
        // The explanation journey always produces rows via the NORMALIZED path.
        originalMode = estrusScoringProperties.getMode();
        originalMaxWindowRows = estrusScoringProperties.getMaxWindowRows();
        estrusScoringProperties.setMode("NORMALIZED");
        estrusScoringProperties.setMaxWindowRows(originalMaxWindowRows);
    }

    @AfterEach
    void tearDownExplanationJourney() {
        estrusScoringProperties.setMode(originalMode);
        estrusScoringProperties.setMaxWindowRows(originalMaxWindowRows);

        // Children first, then bindings, then devices and livestock (FK order).
        if (!livestockIds.isEmpty()) {
            Object[] livestockArgs = livestockIds.toArray();
            String livestockIn = placeholders(livestockIds.size());
            jdbcTemplate.update("DELETE FROM activity_logs WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM temperature_logs WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM alerts WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM estrus_scores WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM health_snapshots WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
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
    }

    // ── The journeys ─────────────────────────────────────────────

    /**
     * Case 1: a row inserted WITHOUT feature_version (how every pre-NIX-390
     * row reached the column — via the ADD COLUMN ... DEFAULT 'LEGACY'
     * backfill) is stamped LEGACY in the DB, and the detail endpoint explains
     * it through the legacy fixed-weight breakdown.
     *
     * <p>Hand computation (dev-measured anchor row, same numbers as
     * {@code EstrusScoreExplainerTest}): step 88 → 20 + (88−50)/100·40 =
     * 35.2; temp Δ0.18 → 0.18/0.2·10 = 9.0; distance 40.30 m → 40.30/500·15
     * = 1.209; weights fixed 0.4/0.3/0.3; weighted sum 14.08 + 2.7 + 0.3627
     * = 17.1427 → 17 = the score column we inserted.</p>
     */
    @Test
    void migrationBackfillsLegacyVersion() {
        long[] ids = insertHead("EE-A");
        long livestockId = ids[0];

        // Insert without feature_version: the migration default stamps it.
        jdbcTemplate.update(
                "INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, "
                        + "temp_delta, distance_delta, advice, scored_at, source) "
                        + "VALUES (?, ?, 17, 88, 0.18, 40.30, 'Not in estrus', NOW(), 'MANUAL_IMPORT')",
                FARM_ID, livestockId);

        // DB-level: the column default backfilled the provenance.
        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT feature_version FROM estrus_scores WHERE livestock_id = ?", livestockId);
        assertThat(row.get("feature_version")).isEqualTo("LEGACY");

        Map<String, Object> detail = estrusDetail(livestockId);

        assertThat(detail.get("featureVersion")).isEqualTo("LEGACY");
        assertThat(detail.get("score")).isEqualTo(17);
        assertThat(d(detail, "activityScore")).isCloseTo(35.2, within(1e-6));
        assertThat(d(detail, "temperatureScore")).isCloseTo(9.0, within(1e-6));
        assertThat(d(detail, "distanceScore")).isCloseTo(1.209, within(1e-6));
        assertThat(d(detail, "weightActivity")).isCloseTo(0.4, within(1e-9));
        assertThat(d(detail, "weightTemperature")).isCloseTo(0.3, within(1e-9));
        assertThat(d(detail, "weightDistance")).isCloseTo(0.3, within(1e-9));
        assertThat(detail.get("distanceParticipated")).isEqualTo(Boolean.TRUE);
        assertThat(detail.get("temperatureParticipated")).isEqualTo(Boolean.TRUE);
        // LEGACY rows carry no level ratios for display.
        assertThat(detail.get("activityRatio")).isNull();
        assertThat(detail.get("distanceRatio")).isNull();
        // The explained breakdown reproduces the stored score: 17.1427 → 17.
        double raw = d(detail, "activityScore") * d(detail, "weightActivity")
                + d(detail, "temperatureScore") * d(detail, "weightTemperature")
                + d(detail, "distanceScore") * d(detail, "weightDistance");
        assertThat(Math.round(raw)).isEqualTo(17L);
        // scoredAt (=timestamp) is carried through on explained rows too.
        assertThat(detail.get("timestamp")).isNotNull();
    }

    /**
     * Case 2: a NORMALIZED row produced by the production telemetry chain
     * (processTelemetry → refreshSnapshot → triggerEstrusScoring) is fully
     * explained: ratio 3.00, components 100/42/100, full weights,
     * distance participated.
     */
    @Test
    void normalizedRowExplainedEndToEnd() {
        long[] ids = insertStandardFixture("EE-B",
                BASELINE_STEP_COUNT, BASELINE_DISTANCE, CURRENT_STEP_COUNT, CURRENT_DISTANCE);
        long livestockId = ids[0];

        triggerScoring(ids);

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT score, feature_version, distance_ratio FROM estrus_scores "
                        + "WHERE livestock_id = ? ORDER BY id DESC LIMIT 1",
                livestockId);
        assertThat(((Number) row.get("score")).intValue()).isEqualTo(83);
        assertThat(row.get("feature_version")).isEqualTo("NORMALIZED-V2");
        assertThat(new BigDecimal(row.get("distance_ratio").toString()))
                .isEqualByComparingTo(new BigDecimal("3.000"));

        Map<String, Object> detail = estrusDetail(livestockId);

        assertThat(detail.get("featureVersion")).isEqualTo("NORMALIZED-V2");
        assertThat(detail.get("timestamp")).isNotNull();
        assertThat(d(detail, "activityRatio")).isCloseTo(3.00, within(1e-9));
        assertThat(d(detail, "distanceRatio")).isCloseTo(3.000, within(1e-9));
        assertThat(d(detail, "activityScore")).isCloseTo(100.0, within(1e-6));
        assertThat(d(detail, "temperatureScore")).isCloseTo(42.0, within(1e-6));
        assertThat(d(detail, "distanceScore")).isCloseTo(100.0, within(1e-6));
        assertThat(d(detail, "weightActivity")).isCloseTo(0.4, within(1e-9));
        assertThat(d(detail, "weightTemperature")).isCloseTo(0.3, within(1e-9));
        assertThat(d(detail, "weightDistance")).isCloseTo(0.3, within(1e-9));
        assertThat(detail.get("distanceParticipated")).isEqualTo(Boolean.TRUE);
        assertThat(detail.get("temperatureParticipated")).isEqualTo(Boolean.TRUE);
        // Baseline card data source: DEFAULT-form audit (no learning ran).
        assertThat(d(detail, "baselineUsed")).isCloseTo(38.50, within(1e-9));
        assertThat(detail.get("baselineSource")).isEqualTo("DEFAULT");
        assertThat(detail.get("baselineComputedAt")).isNull();
    }

    /**
     * Case 3: the CAPSULE-only fixture (no distance channel) explains with
     * renormalized weights — 0.4/0.7 = 4/7 ≈ 0.5714 and 0.3/0.7 = 3/7 ≈
     * 0.4286 — and the distance channel did not participate: score 0,
     * weight 0, ratio null.
     */
    @Test
    void capsuleRowDistanceNotParticipated() {
        long[] ids = insertStandardFixture("EE-C", null, null, null, null);
        long livestockId = ids[0];

        triggerScoring(ids);

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT score, feature_version FROM estrus_scores "
                        + "WHERE livestock_id = ? ORDER BY id DESC LIMIT 1",
                livestockId);
        assertThat(((Number) row.get("score")).intValue()).isEqualTo(75);
        assertThat(row.get("feature_version")).isEqualTo("NORMALIZED-V2");

        Map<String, Object> detail = estrusDetail(livestockId);

        assertThat(detail.get("featureVersion")).isEqualTo("NORMALIZED-V2");
        assertThat(detail.get("distanceParticipated")).isEqualTo(Boolean.FALSE);
        assertThat(detail.get("temperatureParticipated")).isEqualTo(Boolean.TRUE);
        assertThat(d(detail, "weightActivity")).isCloseTo(4.0 / 7.0, within(1e-6));
        assertThat(d(detail, "weightTemperature")).isCloseTo(3.0 / 7.0, within(1e-6));
        assertThat(d(detail, "weightDistance")).isCloseTo(0.0, within(1e-9));
        // Non-participating component: breakdown reports 0 (not null).
        assertThat(d(detail, "distanceScore")).isCloseTo(0.0, within(1e-9));
        assertThat(detail.get("distanceRatio")).isNull();
        assertThat(d(detail, "activityScore")).isCloseTo(100.0, within(1e-6));
        assertThat(d(detail, "temperatureScore")).isCloseTo(42.0, within(1e-6));
    }

    /**
     * Case 4: a livestock without any score row keeps the existing empty-state
     * response shape (score 0, localized advice, empty trend) and every
     * explanation field is null — the client degrades to static help.
     */
    @Test
    void noScoreRow_degradesGracefully() {
        long[] ids = insertHead("EE-D");
        long livestockId = ids[0];

        assertThat(estrusRowCount(livestockId)).isZero();

        Map<String, Object> detail = estrusDetail(livestockId);

        // Existing empty-state semantics, unchanged.
        assertThat(((Number) detail.get("score")).intValue()).isZero();
        assertThat(detail.get("advice")).isNotNull();
        assertThat((List<?>) detail.get("trend7d")).isEmpty();
        assertThat(detail.get("timestamp")).isNull();
        // New fields: all null.
        assertThat(detail.get("featureVersion")).isNull();
        assertThat(detail.get("activityRatio")).isNull();
        assertThat(detail.get("distanceRatio")).isNull();
        assertThat(detail.get("activityScore")).isNull();
        assertThat(detail.get("temperatureScore")).isNull();
        assertThat(detail.get("distanceScore")).isNull();
        assertThat(detail.get("weightActivity")).isNull();
        assertThat(detail.get("weightTemperature")).isNull();
        assertThat(detail.get("weightDistance")).isNull();
        assertThat(detail.get("distanceParticipated")).isNull();
        assertThat(detail.get("temperatureParticipated")).isNull();
        assertThat(detail.get("baselineComputedAt")).isNull();
    }

    // ── Fixture helpers (EstrusNormalizedScoringJourneyTest pattern) ──

    /** The endpoint under test: estrus detail of one livestock. */
    private Map<String, Object> estrusDetail(long livestockId) {
        return getApi(ownerToken, "/api/v1/farms/" + FARM_ID + "/health/estrus/" + livestockId);
    }

    /** Reads a nullable numeric field of the JSON payload as double. */
    private static double d(Map<String, Object> detail, String field) {
        Object value = detail.get(field);
        assertThat(value).as("field %s should be a number", field).isNotNull();
        return ((Number) value).doubleValue();
    }

    /** Minimal livestock + ACTIVE capsule device + open installation row. */
    private long[] insertHead(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "EE-LIVE-" + tag + "-" + seq;
        String deviceCode = "EE-DEV-" + tag + "-" + seq;

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
        livestockIds.add(livestockId);
        deviceIds.add(deviceId);
        return new long[]{livestockId, deviceId};
    }

    /**
     * Standard fixture (shape in {@link EstrusNormalizedScoringJourneyTest}):
     * 3 same-phase baseline windows + a full current window + the 3 baseline
     * temperatures. Pass all-null step/distance for the CAPSULE-only variant.
     */
    private long[] insertStandardFixture(String tag, Integer baselineStep, BigDecimal baselineDistance,
                                         Integer currentStep, BigDecimal currentDistance) {
        long[] ids = insertHead(tag);
        for (int k = 1; k <= BASELINE_WINDOW_COUNT; k++) {
            insertActivityWindow(ids[0], ids[1],
                    anchor.minus(Duration.ofHours(BASELINE_OFFSET_HOURS * k)),
                    BASELINE_ACTIVITY, baselineStep, baselineDistance);
        }
        insertActivityWindow(ids[0], ids[1], anchor, CURRENT_ACTIVITY, currentStep, currentDistance);
        insertBaselineTemps(ids[1]);
        return ids;
    }

    /** 12 frames at 30-minute offsets −6h…−0.5h before {@code windowEnd}. */
    private void insertActivityWindow(long livestockId, long deviceId, Instant windowEnd,
                                      BigDecimal activityIndex, Integer stepCount, BigDecimal distance) {
        for (int j = 0; j < FRAMES_PER_WINDOW; j++) {
            insertActivityFrame(livestockId, deviceId,
                    windowEnd.minus(Duration.ofMinutes(
                            (long) GRANULARITY_MINUTES * (FRAMES_PER_WINDOW - j))),
                    activityIndex, stepCount, distance);
        }
    }

    /** One activity frame; {@code source} honors the CHECK domain of the column. */
    private void insertActivityFrame(long livestockId, long deviceId, Instant recordedAt,
                                     BigDecimal activityIndex, Integer stepCount, BigDecimal distance) {
        ActivityLogJpaEntity frame = new ActivityLogJpaEntity();
        frame.setLivestockId(livestockId);
        frame.setDeviceId(deviceId);
        frame.setActivityIndex(activityIndex);
        frame.setStepCount(stepCount);
        frame.setDistanceMeters(distance);
        frame.setRecordedAt(recordedAt);
        frame.setSource(SOURCE);
        activityLogRepository.save(frame);
    }

    /** One 38.50 temperature per baseline window (3 ≥ minTemperatureSamples−1). */
    private void insertBaselineTemps(long deviceId) {
        Long livestockId = livestockIds.get(livestockIds.size() - 1);
        for (int k = 1; k <= BASELINE_WINDOW_COUNT; k++) {
            TemperatureLogJpaEntity temp = new TemperatureLogJpaEntity();
            temp.setLivestockId(livestockId);
            temp.setDeviceId(deviceId);
            temp.setTemperature(BASELINE_TEMP);
            temp.setBaselineTemp(DEFAULT_BASELINE);
            temp.setRecordedAt(anchor.minus(Duration.ofHours(BASELINE_OFFSET_HOURS * k + 3)));
            temp.setSource(SOURCE);
            temperatureLogRepository.save(temp);
        }
    }

    /**
     * The production entry: one CAPSULE telemetry point carrying only the
     * anchor temperature; its own transaction commits the ingest + snapshot
     * refresh + mode-gated estrus scoring before this returns.
     */
    private void triggerScoring(long[] ids) {
        healthApplicationService.processTelemetry(ids[1], ids[0], FARM_ID,
                DeviceType.CAPSULE, Map.of("temperature", ANCHOR_TEMP), anchor, SOURCE);
    }

    private static String placeholders(int count) {
        return String.join(",", java.util.Collections.nCopies(count, "?"));
    }

    private long estrusRowCount(long livestockId) {
        Long count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM estrus_scores WHERE livestock_id = ?", Long.class, livestockId);
        return count == null ? 0L : count;
    }
}
