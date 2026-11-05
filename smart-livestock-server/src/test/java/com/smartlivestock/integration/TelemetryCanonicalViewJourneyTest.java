package com.smartlivestock.integration;

import com.smartlivestock.iot.domain.model.CoverageCellRow;
import com.smartlivestock.iot.domain.model.CoverageTierTotals;
import com.smartlivestock.iot.domain.model.GatewayDistanceStats;
import com.smartlivestock.iot.domain.model.GatewayUsageSummary;
import com.smartlivestock.iot.domain.model.RssiDistanceSample;
import com.smartlivestock.iot.domain.model.WeakCentroidRow;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * NIX-369: statistics queries read v_telemetry_canonical — one row per
 * (device_id, second) with DATAGEN excluded — while raw-table readers (write
 * idempotency, link diagnostics) keep seeing every physical row.
 *
 * Seeds one physical frame written by both channels (millisecond-differing
 * report_time, the case the (device_id, report_time) unique index cannot
 * catch), plus AGENTIC/THINGSBOARD singles and a DATAGEN training row, then
 * asserts the switched aggregates count 3 canonical frames — not the 5 raw
 * rows.
 *
 * Uses a dedicated device so journey tests sharing one container database
 * (jdbc:tc URL is cached per JVM) cannot pollute each other; the seed cleans
 * its own leftovers before re-inserting because every test method re-seeds.
 */
class TelemetryCanonicalViewJourneyTest extends AbstractJourneyTest {

    private static final String DEVICE_CODE = "DEV-NIX369-VIEW";
    private static final String GATEWAY_ID = "GW-NIX369-TEST";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private DeviceTelemetryLogRepository telemetryLogRepository;

    private long deviceId;

    @BeforeEach
    void seedCanonicalScenario() {
        // uq_devices_code_active is a PARTIAL unique index (deleted_at IS NULL,
        // V20260721100000) — the conflict target must carry the same predicate.
        deviceId = jdbcTemplate.queryForObject("""
                INSERT INTO devices (tenant_id, device_code, device_type, status, battery_level, last_online_at)
                VALUES (1, ?, 'TRACKER', 'ACTIVE', 80, NOW())
                ON CONFLICT (device_code) WHERE deleted_at IS NULL DO UPDATE SET updated_at = NOW()
                RETURNING id
                """, Long.class, DEVICE_CODE);

        // Wipe this scenario's leftovers (gateway rows are unique to it) so
        // every test method starts from exactly the 5 seeded rows.
        jdbcTemplate.update("""
                DELETE FROM device_telemetry_logs
                WHERE device_id = ? OR gateway_id = ?
                """, deviceId, GATEWAY_ID);

        jdbcTemplate.update("""
                INSERT INTO gateway_registry (gateway_id, latitude, longitude)
                VALUES (?, 39.9042000, 116.4074000)
                ON CONFLICT (gateway_id) DO UPDATE
                    SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude
                """, GATEWAY_ID);

        // Anchor on a whole second so the dual pair always lands in the SAME
        // truncated second: per-statement NOW() drifts between INSERTs and
        // would randomly split the pair across two seconds (flaky dedup).
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        // One physical frame, dual-track persistence: AGENTIC first, THINGSBOARD
        // 300 ms later (same second, identical payload).
        insertFrame("AGENTIC_PLATFORM", base.plusMillis(100), -70, 9.5, 39.9043000, 116.4075000, 100);
        insertFrame("THINGSBOARD", base.plusMillis(400), -70, 9.5, 39.9043000, 116.4075000, 100);
        // Single AGENTIC frame.
        insertFrame("AGENTIC_PLATFORM", base.plusSeconds(30), -80, 8.0, 39.9045000, 116.4077000, 120);
        // Single THINGSBOARD weak frame.
        insertFrame("THINGSBOARD", base.plusSeconds(60), -96, 6.0, 39.9047000, 116.4079000, 140);
        // DATAGEN training frame (fixed strong RSSI, far position) — statistics
        // must never see it (AI training keeps reading the base table).
        insertFrame("DATAGEN", base.plusSeconds(45), -56, 12.0, 39.9090000, 116.4120000, 999);
    }

    private void insertFrame(String source, Instant reportTime,
                             int rssi, double snr, double lat, double lng, int step) {
        jdbcTemplate.update("""
                INSERT INTO device_telemetry_logs
                    (device_id, tenant_id, battery_level, rssi, snr, gateway_id,
                     step_number, latitude, longitude, report_time, source)
                VALUES (?, 1, 80, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                deviceId, rssi, snr, GATEWAY_ID, step, lat, lng,
                Timestamp.from(reportTime), source);
    }

    private Instant since2h() {
        return Instant.now().minus(Duration.ofHours(2));
    }

    @Test
    void viewCollapsesDualSourceAndExcludesDatagen() {
        List<Long> devices = List.of(deviceId);

        GatewayUsageSummary usage = telemetryLogRepository
                .aggregateGatewayUsage(devices, since2h(), since2h())
                .stream().findFirst().orElseThrow();
        // 3 canonical frames — the raw table holds 5 (dual pair + DATAGEN).
        assertThat(usage.frames()).isEqualTo(3);
        assertThat(usage.avgRssi()).isCloseTo((-70.0 - 80.0 - 96.0) / 3, within(0.5));

        GatewayDistanceStats distance = telemetryLogRepository
                .aggregateGatewayDistances(deviceId, since2h()).stream().findFirst().orElseThrow();
        assertThat(distance.gatewayId()).isEqualTo(GATEWAY_ID);
        assertThat(distance.frames()).isEqualTo(3);
        // Median of ~14 m / ~42 m / ~70 m frame distances. lastDistanceMeters
        // is intentionally NaN at repository level (GatewayDistanceService
        // fills it from the latest fix, an un-switched query).
        assertThat(distance.medianMeters()).isCloseTo(42.0, within(10.0));

        // Upper bound pushed into the future: seeded frames sit at base+30..60s,
        // which is "now-ish" and would be cut by a strict report_time < now().
        assertThat(telemetryLogRepository
                .roamDistanceSamples(deviceId, since2h(), Instant.now().plus(Duration.ofMinutes(5))))
                .hasSize(3);

        List<RssiDistanceSample> samples = telemetryLogRepository
                .rssiDistanceSamples(GATEWAY_ID, since2h());
        assertThat(samples).hasSize(3);
        assertThat(samples).extracting(RssiDistanceSample::rssi)
                .containsExactlyInAnyOrder(-70, -80, -96);

        CoverageTierTotals totals = telemetryLogRepository.coverageTierTotals(devices, since2h());
        assertThat(totals.totalFrames()).isEqualTo(3);
        assertThat(totals.stableFrames()).isEqualTo(2);
        assertThat(totals.weakFrames()).isEqualTo(1);
        assertThat(totals.edgeFrames()).isZero();

        WeakCentroidRow weak = telemetryLogRepository.weakCentroid(devices, since2h());
        assertThat(weak.frames()).isEqualTo(1);
        assertThat(weak.centroidLat()).isCloseTo(39.9047, within(0.0001));
        assertThat(weak.centroidLng()).isCloseTo(116.4079, within(0.0001));

        List<CoverageCellRow> cells = telemetryLogRepository.coverageCellRows(devices, since2h(), 1);
        assertThat(cells.stream().mapToLong(CoverageCellRow::frames).sum()).isEqualTo(3L);
    }

    @Test
    void viewSurvivorPrefersAgenticPlatform() {
        List<String> rows = jdbcTemplate.queryForList("""
                SELECT source FROM v_telemetry_canonical
                WHERE device_id = ? ORDER BY report_time
                """, String.class, deviceId);
        // 3 canonical rows: the dual pair collapsed to its AGENTIC survivor +
        // the two singles; the DATAGEN row is gone.
        assertThat(rows).containsExactly("AGENTIC_PLATFORM", "AGENTIC_PLATFORM", "THINGSBOARD");
    }

    @Test
    void linkDiagnosticsStillReadsRawTable() {
        // recentLinkQuality is deliberately NOT switched (NIX-369): it must keep
        // every reception path's radio observations, including the DATAGEN rows
        // that live on the base table.
        var stats = telemetryLogRepository
                .recentLinkQuality(deviceId, GATEWAY_ID, since2h(), 10)
                .orElseThrow();
        assertThat(stats.frames()).isEqualTo(5);
        assertThat(stats.avgRssi()).isCloseTo((-70.0 - 70.0 - 80.0 - 96.0 - 56.0) / 5, within(0.5));
    }
}
