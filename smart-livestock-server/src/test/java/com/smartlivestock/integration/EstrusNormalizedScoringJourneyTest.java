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

/**
 * Normalized estrus scoring journey (NIX-380 Task 4, Testcontainers —
 * compile-only on machines without Docker; actual execution happens on the
 * remote testbed via
 * {@code scripts/remote-integration-test.sh --with-journey --target}).
 *
 * <p>Mirrors the {@link IndividualBaselineLearningJourneyTest} fixture style:
 * raw entity inserts for the telemetry history, then ONE
 * {@code HealthApplicationService#processTelemetry} call as the production
 * entry — it ingests the anchor temperature and, through
 * {@code refreshSnapshot → triggerEstrusScoring}, runs the mode-gated scoring
 * path inside its own committed transaction.</p>
 *
 * <p>Item 1 of the task (fresh-DB Flyway validate) is covered by
 * construction: this suite boots a brand-new PostgreSQL via Testcontainers and
 * migrates it with the full Flyway chain before any test runs — a passing run
 * IS the proof.</p>
 *
 * <p><b>Fixture arithmetic (30-minute cadence, 12 frames per 6h window).</b>
 * The anchor {@code T} is the newest temperature sample (inserted by the
 * production call). Windows are half-open {@code [start, end)}; each window
 * holds 12 frames at offsets −6h…−0.5h before its end, and every baseline
 * window ends an exact 24h multiple before {@code T} (same wall-clock phase):</p>
 * <pre>
 *   current   [T−6h,  T)    activityIndex 180, step 600, distance 1500
 *   k = 1     [T−30h, T−24h) activityIndex 60,  step 200, distance 500
 *   k = 2     [T−54h, T−48h) activityIndex 60,  step 200, distance 500
 *   k = 3     [T−78h, T−72h) activityIndex 60,  step 200, distance 500
 *   temps: 38.50 at T−27h/−51h/−75h + anchor 39.05 at T (Δ = 0.55)
 * </pre>
 * <p><b>Expected NORMALIZED row</b> (default ladder 3.0→100, 2.0→95, 1.5→45;
 * weights 0.4/0.3/0.3 over available components): activity mean 180 / pooled
 * baseline median 60 → ratio 3.000000 → ladder 100; temperature Δ0.55 → 42;
 * distance ratio 3.0 → 100 → score = (100·0.4 + 42·0.3 + 100·0.3)/1.0 =
 * 82.6 → 83; step_increase_percent = (3−1)·100 = 200; distance_delta =
 * 1500 − 500 = 1000.00; audit columns DEFAULT-form (snapshot is not LEARNED).
 * CAPSULE-only (step/distance null): distance component unavailable → its
 * weight dropped → score = (100·0.4 + 42·0.3)/0.7 = 75.14 → 75,
 * distance_delta NULL. LEGACY (same fixture): "recent-3 vs rest-4" over the
 * 7 latest rows → recent 3·600 vs older 4·600 → −25%; distance −1500.00;
 * score = (−10·0.4 + 42·0.3 + (−45)·0.3) clamped → 0.</p>
 *
 * <p><b>Read-clamp choice</b> (item 6): mutating {@code maxWindowRows} to 50
 * is far cheaper than growing the fixture past the 600-row default (78h span
 * at 5-minute cadence = 936+ rows per head). 62 rows in the read span + clamp
 * 50 drops exactly the oldest 12 rows = baseline window k=3, so the pooled
 * median becomes (60+90)/2 = 75 instead of 60: ratio 180/75 = 2.4 → ladder 95
 * → step_increase_percent 140, score = (95·0.4 + 42·0.3 + 100·0.3) = 80.6 →
 * 81 — numerically distinct from the unclamped 200/83, which proves the clamp
 * really bit while scoring still landed (2 qualified windows ≥ ceil(3/2)).</p>
 *
 * <p>Properties are mutated in-process on the singleton
 * {@link EstrusScoringProperties} (the {@code BaselineLearningProperties}
 * widening pattern) and restored around every test, so a shared cached Spring
 * context never leaks LEGACY mode or a small clamp into other suites.</p>
 */
public class EstrusNormalizedScoringJourneyTest extends AbstractJourneyTest {

    private static final long FARM_ID = 1L;
    private static final long TENANT_ID = 1L;
    private static final String SOURCE = "MANUAL_IMPORT";
    private static final int GRANULARITY_MINUTES = 30;
    private static final int FRAMES_PER_WINDOW = 12;
    private static final int BASELINE_WINDOW_COUNT = 3;
    /** Same-phase baseline windows end at exact 24h multiples before the anchor. */
    private static final long BASELINE_OFFSET_HOURS = 24;
    /** minTemperatureSamples default: the fixture's 3 baseline + 1 anchor clear it. */
    private static final int EXPECTED_TEMP_SAMPLES = 4;

    private static final BigDecimal BASELINE_ACTIVITY = new BigDecimal("60");
    private static final BigDecimal CURRENT_ACTIVITY = new BigDecimal("180");
    /** Elevated k=2 baseline for the clamp test: defines the pooled median once k=3 is clipped. */
    private static final BigDecimal CLAMP_ELEVATED_BASELINE = new BigDecimal("90");
    private static final Integer BASELINE_STEP_COUNT = 200;
    private static final Integer CURRENT_STEP_COUNT = 600;
    private static final BigDecimal BASELINE_DISTANCE = new BigDecimal("500.00");
    private static final BigDecimal CURRENT_DISTANCE = new BigDecimal("1500.00");
    private static final BigDecimal BASELINE_TEMP = new BigDecimal("38.50");
    private static final BigDecimal ANCHOR_TEMP = new BigDecimal("39.05");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");

    // Expected NORMALIZED row for the standard fixture (derivation in the class javadoc).
    private static final int EXPECTED_SCORE_NORMALIZED = 83;
    private static final int EXPECTED_INCREASE_PERCENT_NORMALIZED = 200;
    private static final String EXPECTED_DISTANCE_DELTA_NORMALIZED = "1000.00";
    /** CAPSULE-only: distance weight dropped → (100·0.4 + 42·0.3)/0.7 → 75. */
    private static final int EXPECTED_SCORE_CAPSULE_ONLY = 75;
    /** LEGACY same fixture: recent 3×600 vs older 4×600 → −25%, score clamps to 0. */
    private static final int EXPECTED_SCORE_LEGACY = 0;
    private static final int EXPECTED_INCREASE_PERCENT_LEGACY = -25;
    private static final String EXPECTED_DISTANCE_DELTA_LEGACY = "-1500.00";
    /** Clamp: k=3 clipped → median (60+90)/2 = 75 → ratio 2.4 → ladder 95 → percent 140, score 81. */
    private static final int EXPECTED_SCORE_CLAMPED = 81;
    private static final int EXPECTED_INCREASE_PERCENT_CLAMPED = 140;

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
    void setUpEstrusScoring() {
        anchor = Instant.now().truncatedTo(ChronoUnit.HOURS);
        // Reset the shared scoring singleton: the cached Spring context may
        // have been mutated by an earlier test in this JVM.
        originalMode = estrusScoringProperties.getMode();
        originalMaxWindowRows = estrusScoringProperties.getMaxWindowRows();
        estrusScoringProperties.setMode("NORMALIZED");
        estrusScoringProperties.setMaxWindowRows(originalMaxWindowRows);
    }

    @AfterEach
    void tearDownEstrusScoring() {
        // Restore the shared singleton first — even on assertion failures.
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

    /** Task item 2: NORMALIZED path lands a row with the full derived shape. */
    @Test
    void normalizedScoringLandsRow() {
        long[] ids = insertStandardFixture("EN-A",
                BASELINE_STEP_COUNT, BASELINE_DISTANCE, CURRENT_STEP_COUNT, CURRENT_DISTANCE);
        long livestockId = ids[0];

        triggerScoring(ids);

        assertThat(estrusRowCount(livestockId)).isEqualTo(1L);
        Map<String, Object> row = latestEstrusRow(livestockId);
        assertThat(((Number) row.get("score")).intValue()).isEqualTo(EXPECTED_SCORE_NORMALIZED);
        assertThat(((Number) row.get("step_increase_percent")).intValue())
                .isEqualTo(EXPECTED_INCREASE_PERCENT_NORMALIZED);
        assertThat(new BigDecimal(row.get("temp_delta").toString()))
                .isEqualByComparingTo(new BigDecimal("0.55"));
        assertThat(new BigDecimal(row.get("distance_delta").toString()))
                .isEqualByComparingTo(new BigDecimal(EXPECTED_DISTANCE_DELTA_NORMALIZED));
        assertDefaultAuditForm(row);
        assertThat(row.get("source")).isEqualTo(SOURCE);
        assertThat(row.get("advice")).isNotNull();
    }

    /** Task item 3: CAPSULE-only channels (no step/distance) still land a row. */
    @Test
    void capsuleOnlyScoringDropsDistanceWeight() {
        long[] ids = insertStandardFixture("EN-B", null, null, null, null);
        long livestockId = ids[0];

        triggerScoring(ids);

        assertThat(estrusRowCount(livestockId)).isEqualTo(1L);
        Map<String, Object> row = latestEstrusRow(livestockId);
        assertThat(((Number) row.get("score")).intValue()).isEqualTo(EXPECTED_SCORE_CAPSULE_ONLY);
        // The activity component is unchanged: activityIndex ratio 3.0 → 200.
        assertThat(((Number) row.get("step_increase_percent")).intValue())
                .isEqualTo(EXPECTED_INCREASE_PERCENT_NORMALIZED);
        assertThat(new BigDecimal(row.get("temp_delta").toString()))
                .isEqualByComparingTo(new BigDecimal("0.55"));
        // Distance component unavailable → no LEGACY-shaped meter delta.
        assertThat(row.get("distance_delta")).isNull();
        assertDefaultAuditForm(row);
        assertThat(row.get("source")).isEqualTo(SOURCE);
    }

    /** Task item 4: 3 current-window samples (< min 4) → guard fires, no row. */
    @Test
    void starvedCurrentWindowWritesNothing() {
        long[] ids = insertHead("EN-C");
        long livestockId = ids[0];
        long deviceId = ids[1];
        // Baseline windows are fully qualified: the ONLY miss is the current
        // window sample count, so the guard under test is guard 3 exactly.
        for (int k = 1; k <= BASELINE_WINDOW_COUNT; k++) {
            insertActivityWindow(livestockId, deviceId,
                    anchor.minus(Duration.ofHours(BASELINE_OFFSET_HOURS * k)),
                    BASELINE_ACTIVITY, null, null);
        }
        // 3 frames in [T−90min, T) — below minCurrentActivitySamples=4, and
        // the stepCount fallback channel starves identically (null step).
        Instant windowEnd = anchor;
        for (int j = 0; j < 3; j++) {
            insertActivityFrame(livestockId, deviceId,
                    windowEnd.minus(Duration.ofMinutes((long) GRANULARITY_MINUTES * (3 - j))),
                    CURRENT_ACTIVITY, null, null);
        }
        insertBaselineTemps(deviceId);
        assertThat(estrusRowCount(livestockId)).isZero();

        triggerScoring(ids);

        // Fail-silent contract: no estrus_scores row. The snapshot row exists
        // (refreshSnapshot always upserts it) but its score stays untouched.
        assertThat(estrusRowCount(livestockId)).isZero();
        assertThat(snapshotEstrusScore(livestockId)).isZero();
    }

    /** Task item 5: mode=LEGACY flips the same fixture onto the old formula. */
    @Test
    void legacyModeRollsBackToShortWindowFormula() {
        long[] ids = insertStandardFixture("EN-D",
                BASELINE_STEP_COUNT, BASELINE_DISTANCE, CURRENT_STEP_COUNT, CURRENT_DISTANCE);
        long livestockId = ids[0];

        estrusScoringProperties.setMode("LEGACY");
        triggerScoring(ids);

        assertThat(estrusRowCount(livestockId)).isEqualTo(1L);
        Map<String, Object> row = latestEstrusRow(livestockId);
        assertThat(((Number) row.get("score")).intValue()).isEqualTo(EXPECTED_SCORE_LEGACY);
        assertThat(((Number) row.get("step_increase_percent")).intValue())
                .isEqualTo(EXPECTED_INCREASE_PERCENT_LEGACY);
        // The temperature component is baseline-relative in both paths.
        assertThat(new BigDecimal(row.get("temp_delta").toString()))
                .isEqualByComparingTo(new BigDecimal("0.55"));
        assertThat(new BigDecimal(row.get("distance_delta").toString()))
                .isEqualByComparingTo(new BigDecimal(EXPECTED_DISTANCE_DELTA_LEGACY));
        assertDefaultAuditForm(row);
        assertThat(row.get("source")).isEqualTo(SOURCE);
        assertThat(snapshotEstrusScore(livestockId)).isZero();
    }

    /**
     * Task item 6: the read clamp bites (maxWindowRows 50 vs 62 span rows) yet
     * scoring still lands — the clipped k=3 window leaves 2 qualified windows,
     * and the pooled median moves 60 → 75, which shows up as percent 140 /
     * score 81 instead of the unclamped 200/83.
     */
    @Test
    void readClampKeepsScoringOnClippedWindow() {
        estrusScoringProperties.setMaxWindowRows(50);
        long[] ids = insertClampFixture("EN-E");
        long livestockId = ids[0];

        assertThat(activityRowCount(livestockId)).isEqualTo(62L);

        triggerScoring(ids);

        assertThat(estrusRowCount(livestockId)).isEqualTo(1L);
        Map<String, Object> row = latestEstrusRow(livestockId);
        assertThat(((Number) row.get("score")).intValue()).isEqualTo(EXPECTED_SCORE_CLAMPED);
        assertThat(((Number) row.get("step_increase_percent")).intValue())
                .isEqualTo(EXPECTED_INCREASE_PERCENT_CLAMPED);
        assertThat(new BigDecimal(row.get("temp_delta").toString()))
                .isEqualByComparingTo(new BigDecimal("0.55"));
        // Distance values are uniform across the surviving windows, so the
        // clamp does not move this channel: ratio 3.0, delta 1000.00.
        assertThat(new BigDecimal(row.get("distance_delta").toString()))
                .isEqualByComparingTo(new BigDecimal(EXPECTED_DISTANCE_DELTA_NORMALIZED));
        assertDefaultAuditForm(row);
    }

    /** Task item 7: the scored value is linked into health_snapshots. */
    @Test
    void snapshotMirrorsFreshScore() {
        long[] ids = insertStandardFixture("EN-F",
                BASELINE_STEP_COUNT, BASELINE_DISTANCE, CURRENT_STEP_COUNT, CURRENT_DISTANCE);
        long livestockId = ids[0];

        triggerScoring(ids);

        assertThat(estrusRowCount(livestockId)).isEqualTo(1L);
        assertThat(((Number) latestEstrusRow(livestockId).get("score")).intValue())
                .isEqualTo(EXPECTED_SCORE_NORMALIZED);
        assertThat(snapshotEstrusScore(livestockId)).isEqualTo(EXPECTED_SCORE_NORMALIZED);
        // The snapshot stays DEFAULT-form: no learning ran in this journey.
        Map<String, Object> snap = jdbcTemplate.queryForMap(
                "SELECT baseline_temp, baseline_source FROM health_snapshots WHERE livestock_id = ?",
                livestockId);
        assertThat(snap.get("baseline_source")).isEqualTo("DEFAULT");
        assertThat(new BigDecimal(snap.get("baseline_temp").toString()))
                .isEqualByComparingTo(DEFAULT_BASELINE);
    }

    // ── Fixture helpers (IndividualBaselineLearningJourneyTest pattern) ──

    /** Minimal livestock + ACTIVE capsule device + open installation row. */
    private long[] insertHead(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "EN-LIVE-" + tag + "-" + seq;
        String deviceCode = "EN-DEV-" + tag + "-" + seq;

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
     * Standard fixture (shape in the class javadoc): 3 same-phase baseline
     * windows + a full current window, then the 3 baseline temperatures. The
     * baseline and current windows carry DISTINCT step/distance levels (the
     * 3x rise the ladder keys on); pass all-null for the CAPSULE-only variant.
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

    /**
     * Clamp fixture: k=2 carries the elevated 90-activityIndex so that once
     * the clamp drops k=3 the pooled median becomes (60+90)/2 = 75 — a
     * numerically observable difference from the unclamped median 60.
     * 14 filler frames inside the telemetry gap (T−24h, T−6h) push the window
     * read to 62 rows &gt; maxWindowRows=50, so exactly the oldest 12 rows
     * (all of k=3) fall out of the read.
     */
    private long[] insertClampFixture(String tag) {
        long[] ids = insertHead(tag);
        insertActivityWindow(ids[0], ids[1],
                anchor.minus(Duration.ofHours(BASELINE_OFFSET_HOURS)),
                BASELINE_ACTIVITY, CURRENT_STEP_COUNT, BASELINE_DISTANCE);
        insertActivityWindow(ids[0], ids[1],
                anchor.minus(Duration.ofHours(2 * BASELINE_OFFSET_HOURS)),
                CLAMP_ELEVATED_BASELINE, CURRENT_STEP_COUNT, BASELINE_DISTANCE);
        insertActivityWindow(ids[0], ids[1],
                anchor.minus(Duration.ofHours(3 * BASELINE_OFFSET_HOURS)),
                BASELINE_ACTIVITY, CURRENT_STEP_COUNT, BASELINE_DISTANCE);

        // Gap fillers: newest of the pre-current rows, inside no scoring
        // window — they only inflate the read past the clamp.
        Instant fillerStart = anchor.minus(Duration.ofHours(23)).minus(Duration.ofMinutes(GRANULARITY_MINUTES));
        for (int j = 0; j < 14; j++) {
            insertActivityFrame(ids[0], ids[1],
                    fillerStart.plus(Duration.ofMinutes((long) GRANULARITY_MINUTES * j)),
                    BASELINE_ACTIVITY, null, null);
        }
        insertActivityWindow(ids[0], ids[1], anchor, CURRENT_ACTIVITY, CURRENT_STEP_COUNT, CURRENT_DISTANCE);
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
     * anchor temperature. Its own {@code @Transactional} commits the ingest +
     * snapshot refresh + mode-gated estrus scoring before this returns.
     */
    private void triggerScoring(long[] ids) {
        healthApplicationService.processTelemetry(ids[1], ids[0], FARM_ID,
                DeviceType.CAPSULE, Map.of("temperature", ANCHOR_TEMP), anchor, SOURCE);
    }

    private static String placeholders(int count) {
        return String.join(",", java.util.Collections.nCopies(count, "?"));
    }

    // ── Assertion helpers ────────────────────────────────────────

    private long estrusRowCount(long livestockId) {
        Long count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM estrus_scores WHERE livestock_id = ?", Long.class, livestockId);
        return count == null ? 0L : count;
    }

    private long activityRowCount(long livestockId) {
        Long count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM activity_logs WHERE livestock_id = ?", Long.class, livestockId);
        return count == null ? 0L : count;
    }

    /** Newest estrus_scores row of the livestock (fresh fixture → the only one). */
    private Map<String, Object> latestEstrusRow(long livestockId) {
        return jdbcTemplate.queryForMap(
                "SELECT score, step_increase_percent, temp_delta, distance_delta, "
                        + "baseline_used, baseline_source, baseline_computed_at, baseline_algorithm_version, "
                        + "source, advice, scored_at FROM estrus_scores "
                        + "WHERE livestock_id = ? ORDER BY id DESC LIMIT 1",
                livestockId);
    }

    /** DEFAULT-form audit columns: fixed 38.50, DEFAULT, no computation evidence. */
    private void assertDefaultAuditForm(Map<String, Object> row) {
        assertThat(new BigDecimal(row.get("baseline_used").toString()))
                .isEqualByComparingTo(DEFAULT_BASELINE);
        assertThat(row.get("baseline_source")).isEqualTo("DEFAULT");
        assertThat(row.get("baseline_computed_at")).isNull();
        assertThat(row.get("baseline_algorithm_version")).isNull();
    }

    private int snapshotEstrusScore(long livestockId) {
        Integer score = jdbcTemplate.queryForObject(
                "SELECT estrus_score FROM health_snapshots WHERE livestock_id = ?",
                Integer.class, livestockId);
        return score == null ? 0 : score;
    }
}
