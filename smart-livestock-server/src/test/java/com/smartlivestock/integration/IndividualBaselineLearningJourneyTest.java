package com.smartlivestock.integration;

import com.smartlivestock.health.application.service.IndividualBaselineLearningService;
import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.health.domain.service.BaselineLearningResult;
import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import com.smartlivestock.identity.application.TenantZoneResolver;
import com.smartlivestock.iot.domain.model.DeviceType;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Individual baseline auto-learning journey (plan 2026-11-03 Task 3,
 * Testcontainers — like the drinking journey, compile-only on machines
 * without Docker; actual execution happens on the remote testbed via
 * {@code scripts/remote-integration-test.sh --with-journey --target}).
 *
 * <p>End-to-end write path: direct-inserted MANUAL_IMPORT night series →
 * first processTelemetry stamps the DEFAULT baseline on the new log →
 * {@code recalculate} learns the per-animal baseline (weighted mean, ±2σ
 * band, sample evidence) and persists it with a targeted snapshot UPDATE →
 * the next telemetry log carries the LEARNED baseline while every
 * pre-learning row stays untouched (zero historical rewrite) → repeat runs
 * are idempotent → a data-starved animal stays DEFAULT with NULL evidence.</p>
 *
 * <p>Timezone: the fixture tenant is switched to {@code Africa/Nairobi}
 * (fixed UTC+3, no DST) so the kernel's night window (farm-local hour
 * ≥ 21 or &lt; 6) is deterministic. The telemetry logs fed to
 * processTelemetry are stamped at local noon on purpose: they can never
 * enter the night-fallback admission path, which keeps the learned-value
 * assertions independent of the wall clock the suite happens to run at.</p>
 */
public class IndividualBaselineLearningJourneyTest extends AbstractJourneyTest {

    private static final long FARM_ID = 1L;
    private static final long TENANT_ID = 1L;
    private static final ZoneId EAT = ZoneId.of("Africa/Nairobi");
    private static final BigDecimal DEFAULT_BASELINE = new BigDecimal("38.50");
    /** Fixed per-UTC-slot values; every qualified local day averages 39.40. */
    private static final BigDecimal TEMP_1900 = new BigDecimal("39.20");
    private static final BigDecimal TEMP_2000 = new BigDecimal("39.40");
    private static final BigDecimal TEMP_2130 = new BigDecimal("39.60");

    @Autowired
    private IndividualBaselineLearningService learningService;

    @Autowired
    private HealthApplicationService healthApplicationService;

    @Autowired
    private TemperatureLogJpaRepository temperatureLogRepository;

    @Autowired
    private TenantZoneResolver tenantZoneResolver;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Long livestockAId;
    private Long livestockBId;
    private Long deviceAId;
    private Long deviceBId;
    private String originalTenantTimezone;
    /** Earliest admitted sample of the qualified days = UTC −9d 19:00. */
    private Instant earliestQualifiedSampleAt;

    /** Unique suffixes so repeated runs never collide with seed codes. */
    private static final AtomicLong CODE_SEQ = new AtomicLong(System.currentTimeMillis() % 1_000_000);

    @BeforeEach
    void setUpBaselineLearning() {
        // Tenant timezone → EAT: the farm inherits it through the resolver
        // chain. The resolver caches zones in-process, so evict after the
        // raw JDBC update or a pre-cached UTC would silently win.
        originalTenantTimezone = jdbcTemplate.queryForObject(
                "SELECT timezone FROM tenants WHERE id = ?", String.class, TENANT_ID);
        jdbcTemplate.update("UPDATE tenants SET timezone = 'Africa/Nairobi' WHERE id = ?", TENANT_ID);
        tenantZoneResolver.evictFarm(FARM_ID);
        tenantZoneResolver.evictTenant(TENANT_ID);

        livestockAId = insertLivestockWithCapsule("BLA");
        deviceAId = lastCreatedDeviceId;
        livestockBId = insertLivestockWithCapsule("BLB");
        deviceBId = lastCreatedDeviceId;
        // B never receives telemetry in this journey; give it its snapshot row
        // directly (all other columns are DB defaults, incl. DEFAULT/38.50) so
        // the insufficient-data run asserts on a real snapshot. Raw JDBC
        // because the repository's @Modifying UPSERT needs an active
        // transaction that a non-transactional journey test does not have.
        jdbcTemplate.update(
                "INSERT INTO health_snapshots (livestock_id, farm_id) VALUES (?, ?)",
                livestockBId, FARM_ID);
    }

    @AfterEach
    void tearDownBaselineLearning() {
        // Children first: logs/alerts/estrus/snapshots, then bindings, then
        // devices and livestock (FK order). anomaly_scores carries no FK.
        if (livestockAId != null) {
            jdbcTemplate.update("DELETE FROM temperature_logs WHERE livestock_id IN (?, ?)",
                    livestockAId, livestockBId);
            jdbcTemplate.update("DELETE FROM alerts WHERE livestock_id IN (?, ?)",
                    livestockAId, livestockBId);
            jdbcTemplate.update("DELETE FROM estrus_scores WHERE livestock_id IN (?, ?)",
                    livestockAId, livestockBId);
            jdbcTemplate.update("DELETE FROM health_snapshots WHERE livestock_id IN (?, ?)",
                    livestockAId, livestockBId);
        }
        if (deviceAId != null) {
            jdbcTemplate.update("DELETE FROM installations WHERE device_id IN (?, ?)",
                    deviceAId, deviceBId);
            jdbcTemplate.update("DELETE FROM devices WHERE id IN (?, ?)", deviceAId, deviceBId);
        }
        if (livestockAId != null) {
            jdbcTemplate.update("DELETE FROM livestock WHERE id IN (?, ?)", livestockAId, livestockBId);
        }
        // Restore the shared tenant row and drop the resolver's cached zone.
        jdbcTemplate.update("UPDATE tenants SET timezone = ? WHERE id = ?",
                originalTenantTimezone, TENANT_ID);
        tenantZoneResolver.evictFarm(FARM_ID);
        tenantZoneResolver.evictTenant(TENANT_ID);
    }

    // ── Fixture helpers (ContactAnalysisServiceIntegrationTest pattern) ──

    private Long lastCreatedDeviceId;

    /** Minimal livestock + ACTIVE capsule device + open installation row. */
    private Long insertLivestockWithCapsule(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "BL-LIVE-" + tag + "-" + seq;
        String deviceCode = "BL-DEV-" + tag + "-" + seq;

        jdbcTemplate.update(
                "INSERT INTO livestock (farm_id, livestock_code, breed, gender) VALUES (?, ?, 'OTHER', 'FEMALE')",
                FARM_ID, livestockCode);
        jdbcTemplate.update(
                "INSERT INTO devices (tenant_id, device_code, device_type, status) VALUES (?, ?, 'CAPSULE', 'ACTIVE')",
                TENANT_ID, deviceCode);
        Long livestockId = jdbcTemplate.queryForObject(
                "SELECT id FROM livestock WHERE livestock_code = ?", Long.class, livestockCode);
        lastCreatedDeviceId = jdbcTemplate.queryForObject(
                "SELECT id FROM devices WHERE device_code = ?", Long.class, deviceCode);
        jdbcTemplate.update(
                "INSERT INTO installations (device_id, livestock_id, installed_at) VALUES (?, ?, NOW())",
                lastCreatedDeviceId, livestockId);
        return livestockId;
    }

    /**
     * Insert one night series over UTC days [{@code fromDaysBack} ..
     * {@code toDaysBack}]: three rows per UTC day at 19:00/20:00/21:30 UTC =
     * 22:00/23:00/00:30 EAT — all inside the night window (hour ≥ 21 or
     * &lt; 6). The A-series deliberately starts at UTC day −9 (not −8): the
     * trailing 21:30 row of each UTC day spills into the NEXT local day, so
     * "today" (which also receives the processTelemetry logs) never
     * accumulates enough admitted samples to qualify — that keeps the
     * learned-value assertions independent of the suite's run time. Day −9
     * itself holds only its own 19:00/20:00 pair (2 ≥ min-samples-per-day)
     * and still qualifies, so A ends with exactly 8 qualified days.
     */
    private void insertNightSeries(Long livestockId, Long deviceId, int fromDaysBack, int toDaysBack) {
        for (int daysBack = fromDaysBack; daysBack >= toDaysBack; daysBack--) {
            LocalDate utcDay = LocalDate.now(ZoneOffset.UTC).minusDays(daysBack);
            insertTemp(livestockId, deviceId, utcDay.atTime(19, 0).toInstant(ZoneOffset.UTC), TEMP_1900);
            insertTemp(livestockId, deviceId, utcDay.atTime(20, 0).toInstant(ZoneOffset.UTC), TEMP_2000);
            insertTemp(livestockId, deviceId, utcDay.atTime(21, 30).toInstant(ZoneOffset.UTC), TEMP_2130);
        }
    }

    private TemperatureLogJpaEntity insertTemp(Long livestockId, Long deviceId, Instant recordedAt, BigDecimal temp) {
        TemperatureLogJpaEntity entity = new TemperatureLogJpaEntity();
        entity.setLivestockId(livestockId);
        entity.setDeviceId(deviceId);
        entity.setTemperature(temp);
        entity.setBaselineTemp(DEFAULT_BASELINE);
        entity.setRecordedAt(recordedAt);
        entity.setSource("MANUAL_IMPORT");
        // baseline_source left at the entity default ("DEFAULT") — the column
        // default fallback the contract describes.
        return temperatureLogRepository.save(entity);
    }

    /**
     * A guaranteed farm-local-noon instant: 12:00 EAT of today. On morning
     * runs it is slightly in the future, in which case the learning kernel
     * silently trims it from the window — either way it can never be
     * admitted as a night sample, so it cannot shift the learned values.
     */
    private static Instant noonEat() {
        return LocalDate.now(EAT).atTime(LocalTime.NOON).atZone(EAT).toInstant();
    }

    /**
     * Latest MANUAL_IMPORT log row of the device by id — the id order is the
     * insert order, which sidesteps binding tz-less {@code recorded_at}
     * timestamps from JDBC.
     */
    private Map<String, Object> latestTempLog(Long deviceId) {
        return jdbcTemplate.queryForMap(
                "SELECT baseline_temp, baseline_source FROM temperature_logs "
                        + "WHERE device_id = ? AND source = 'MANUAL_IMPORT' ORDER BY id DESC LIMIT 1",
                deviceId);
    }

    private Map<String, Object> snapshotRow(Long livestockId) {
        return jdbcTemplate.queryForMap(
                "SELECT baseline_temp, baseline_source, baseline_sample_count, baseline_qualified_days, "
                        + "baseline_window_start, baseline_computed_at, baseline_band_low, baseline_band_high, "
                        + "baseline_algorithm_version FROM health_snapshots WHERE livestock_id = ?",
                livestockId);
    }

    private List<Map<String, Object>> allTempLogs(Long livestockId) {
        return jdbcTemplate.queryForList(
                "SELECT baseline_temp, baseline_source FROM temperature_logs WHERE livestock_id = ? "
                        + "ORDER BY recorded_at",
                livestockId);
    }

    // ── The journey ──────────────────────────────────────────────

    @Test
    void individualBaselineLearningJourney() {
        // 1)+2) Fixtures: A learns, B stays starved. 8 UTC days × 3 night
        // rows for A (= 24 rows), 2 days × 3 rows for B.
        insertNightSeries(livestockAId, deviceAId, 9, 2);
        earliestQualifiedSampleAt = LocalDate.now(ZoneOffset.UTC).minusDays(9)
                .atTime(19, 0).toInstant(ZoneOffset.UTC);
        insertNightSeries(livestockBId, deviceBId, 3, 2);

        // 3) First telemetry: the snapshot does not exist yet (ingest runs
        // before refreshSnapshot creates it), so the new log is stamped with
        // the DEFAULT baseline and its source.
        Instant firstTelemetryAt = noonEat();
        healthApplicationService.processTelemetry(deviceAId, livestockAId, FARM_ID,
                DeviceType.CAPSULE, Map.of("temperature", new BigDecimal("39.3")),
                firstTelemetryAt, "MANUAL_IMPORT");
        Map<String, Object> firstLog = latestTempLog(deviceAId);
        assertThat(new BigDecimal(firstLog.get("baseline_temp").toString()))
                .isEqualByComparingTo(DEFAULT_BASELINE);
        assertThat(firstLog.get("baseline_source")).isEqualTo("DEFAULT");

        // 4) Learn: DEFAULT → LEARNED with the full evidence set.
        BaselineLearningResult result = learningService.recalculate(livestockAId, true);
        assertThat(result).isNotNull();
        assertThat(result.learnedNow()).isTrue();
        assertThat(result.insufficientData()).isFalse();
        assertThat(result.sourceAfterRun()).isEqualTo("LEARNED");
        // Weighted mean of the qualified days: day −9 contributes
        // (39.20+39.40)/2 = 39.30, the other seven days 39.40 → mean 39.3875
        // → 39.39 (the plan's "≈39.40 ±0.05"). Band = mean ± 2σ → ≈39.07/39.71.
        assertThat(result.baselineTemp()).isBetween(new BigDecimal("39.35"), new BigDecimal("39.45"));
        assertThat(result.bandLow()).isBetween(new BigDecimal("38.90"), new BigDecimal("39.10"));
        assertThat(result.bandHigh()).isBetween(new BigDecimal("39.70"), new BigDecimal("39.90"));
        assertThat(result.admittedSampleCount()).isEqualTo(24);
        assertThat(result.qualifiedDays()).isEqualTo(8);
        assertThat(result.windowStart()).isEqualTo(earliestQualifiedSampleAt);

        // Persisted row: the targeted UPDATE wrote every learned-baseline column.
        Map<String, Object> snap = snapshotRow(livestockAId);
        assertThat(snap.get("baseline_source")).isEqualTo("LEARNED");
        assertThat(new BigDecimal(snap.get("baseline_temp").toString()))
                .isEqualByComparingTo(result.baselineTemp());
        assertThat(((Number) snap.get("baseline_sample_count")).intValue()).isEqualTo(24);
        assertThat(((Number) snap.get("baseline_qualified_days")).intValue()).isEqualTo(8);
        assertThat(snap.get("baseline_window_start")).isNotNull();
        assertThat(snap.get("baseline_computed_at")).isNotNull();
        assertThat(new BigDecimal(snap.get("baseline_band_low").toString()))
                .isEqualByComparingTo(result.bandLow());
        assertThat(new BigDecimal(snap.get("baseline_band_high").toString()))
                .isEqualByComparingTo(result.bandHigh());
        assertThat(snap.get("baseline_algorithm_version")).isEqualTo("V1");

        // 5) Next telemetry carries the learned baseline; every pre-learning
        // row (the DEFAULT-stamped telemetry log and the 24 direct inserts)
        // keeps baseline_temp=38.50 / baseline_source=DEFAULT — zero rewrite.
        Instant secondTelemetryAt = noonEat().plusSeconds(300);
        healthApplicationService.processTelemetry(deviceAId, livestockAId, FARM_ID,
                DeviceType.CAPSULE, Map.of("temperature", new BigDecimal("39.3")),
                secondTelemetryAt, "MANUAL_IMPORT");
        Map<String, Object> secondLog = latestTempLog(deviceAId);
        assertThat(new BigDecimal(secondLog.get("baseline_temp").toString()))
                .isEqualByComparingTo(result.baselineTemp());
        assertThat(secondLog.get("baseline_source")).isEqualTo("LEARNED");

        List<Map<String, Object>> allLogs = allTempLogs(livestockAId);
        assertThat(allLogs).hasSize(26); // 24 direct + 2 telemetry
        List<Map<String, Object>> historical = allLogs.stream()
                .filter(row -> !"LEARNED".equals(row.get("baseline_source")))
                .toList();
        assertThat(historical).hasSize(25);
        assertThat(historical).allSatisfy(row -> {
            assertThat(new BigDecimal(row.get("baseline_temp").toString()))
                    .isEqualByComparingTo(DEFAULT_BASELINE);
            assertThat(row.get("baseline_source")).isEqualTo("DEFAULT");
        });

        // 6) Idempotency: a repeat run over the same window yields the same
        // learned values and no second DEFAULT→LEARNED flip.
        BaselineLearningResult repeat = learningService.recalculate(livestockAId, true);
        assertThat(repeat).isNotNull();
        assertThat(repeat.learnedNow()).isFalse();
        assertThat(repeat.insufficientData()).isFalse();
        assertThat(repeat.baselineTemp()).isEqualByComparingTo(result.baselineTemp());
        assertThat(repeat.bandLow()).isEqualByComparingTo(result.bandLow());
        assertThat(repeat.bandHigh()).isEqualByComparingTo(result.bandHigh());
        assertThat(repeat.admittedSampleCount()).isEqualTo(result.admittedSampleCount());
        assertThat(repeat.qualifiedDays()).isEqualTo(result.qualifiedDays());

        // 7) Starved animal: 2 qualified days < min-qualified-days → no
        // learning, snapshot row untouched (DEFAULT/38.50, NULL band/evidence).
        BaselineLearningResult starved = learningService.recalculate(livestockBId, true);
        assertThat(starved).isNotNull();
        assertThat(starved.insufficientData()).isTrue();
        assertThat(starved.learnedNow()).isFalse();
        assertThat(starved.sourceAfterRun()).isEqualTo("DEFAULT");
        assertThat(starved.bandLow()).isNull();
        assertThat(starved.bandHigh()).isNull();

        Map<String, Object> starvedSnap = snapshotRow(livestockBId);
        assertThat(starvedSnap.get("baseline_source")).isEqualTo("DEFAULT");
        assertThat(new BigDecimal(starvedSnap.get("baseline_temp").toString()))
                .isEqualByComparingTo(DEFAULT_BASELINE);
        assertThat(starvedSnap.get("baseline_sample_count")).isNull();
        assertThat(starvedSnap.get("baseline_qualified_days")).isNull();
        assertThat(starvedSnap.get("baseline_window_start")).isNull();
        assertThat(starvedSnap.get("baseline_computed_at")).isNull();
        assertThat(starvedSnap.get("baseline_band_low")).isNull();
        assertThat(starvedSnap.get("baseline_band_high")).isNull();
        assertThat(starvedSnap.get("baseline_algorithm_version")).isNull();

        // 8) Night-fallback path: the whole journey runs without any
        // activity_logs row, so the quiet-state screening exercised above IS
        // the activity-missing night fallback — covered by construction.
    }
}
