package com.smartlivestock.integration;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Pins the default-partition rebalance behavior the app relies on at startup
 * (PartitionMaintenanceService → partition_ops.ensure_month_partition).
 *
 * Regression guard for the NIX-184 generated-column fix: the row move must
 * round-trip WITHOUT the GENERATED ALWAYS stored columns, because re-inserting
 * them is rejected by PostgreSQL ("cannot insert a non-DEFAULT value into
 * column delta") — the failure mode that crashed application startup on
 * databases still carrying the pre-fix function. If anyone reintroduces a
 * whole-row copy into the move, the first test fails.
 */
@Testcontainers(disabledWithoutDocker = true)
class PartitionOpsJourneyTest extends AbstractJourneyTest {

    private static final String GENERATED_TABLE = "zc_journey_temp_logs";
    private static final String PLAIN_TABLE = "zc_journey_plain_logs";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void dropScratchTables() {
        dropScratch();
    }

    @AfterEach
    void cleanup() {
        dropScratch();
    }

    private void dropScratch() {
        jdbcTemplate.execute("DROP TABLE IF EXISTS " + GENERATED_TABLE + "_2026_09");
        jdbcTemplate.execute("DROP TABLE IF EXISTS " + GENERATED_TABLE + "_default");
        jdbcTemplate.execute("DROP TABLE IF EXISTS " + GENERATED_TABLE);
        jdbcTemplate.execute("DROP TABLE IF EXISTS " + PLAIN_TABLE + "_2026_06");
        jdbcTemplate.execute("DROP TABLE IF EXISTS " + PLAIN_TABLE + "_default");
        jdbcTemplate.execute("DROP TABLE IF EXISTS " + PLAIN_TABLE);
    }

    @Test
    @DisplayName("moving rows out of a default partition round-trips without the generated column")
    void generatedColumnTable_movesRowsOutOfDefault() {
        // Same column layout as temperature_logs: GENERATED ALWAYS stored delta.
        jdbcTemplate.execute("CREATE TABLE " + GENERATED_TABLE + " ("
                + " id bigint NOT NULL,"
                + " device_id bigint NOT NULL,"
                + " temperature numeric(5,2) NOT NULL,"
                + " baseline_temp numeric(5,2) NOT NULL DEFAULT 38.50,"
                + " delta numeric(5,2) GENERATED ALWAYS AS (temperature - baseline_temp) STORED,"
                + " recorded_at timestamp NOT NULL"
                + ") PARTITION BY RANGE (recorded_at)");
        jdbcTemplate.execute("CREATE TABLE " + GENERATED_TABLE
                + "_default PARTITION OF " + GENERATED_TABLE + " DEFAULT");
        jdbcTemplate.update("INSERT INTO " + GENERATED_TABLE
                        + " (id, device_id, temperature, recorded_at) VALUES (?, ?, ?, ?)",
                1L, 214L, new BigDecimal("39.00"), java.sql.Timestamp.valueOf("2026-09-28 00:40:00"));
        jdbcTemplate.update("INSERT INTO " + GENERATED_TABLE
                        + " (id, device_id, temperature, recorded_at) VALUES (?, ?, ?, ?)",
                2L, 214L, new BigDecimal("39.50"), java.sql.Timestamp.valueOf("2026-09-28 01:00:00"));

        Long moved = jdbcTemplate.queryForObject(
                "SELECT partition_ops.ensure_month_partition(?::regclass, ?::date)",
                Long.class, GENERATED_TABLE, "2026-09-01");

        assertThat(moved).isEqualTo(2L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT count(*) FROM " + GENERATED_TABLE + "_default", Long.class)).isZero();

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT id, temperature, delta, recorded_at FROM " + GENERATED_TABLE + "_2026_09 ORDER BY id");
        assertThat(rows).hasSize(2);
        // Delta must be recomputed by the server, not carried over as a value.
        assertThat(rows.get(0).get("delta")).isEqualTo(new BigDecimal("0.50"));
        assertThat(rows.get(1).get("delta")).isEqualTo(new BigDecimal("1.00"));

        // Partition already exists → second call is a no-op.
        Long again = jdbcTemplate.queryForObject(
                "SELECT partition_ops.ensure_month_partition(?::regclass, ?::date)",
                Long.class, GENERATED_TABLE, "2026-09-01");
        assertThat(again).isZero();
    }

    @Test
    @DisplayName("tables without generated columns keep moving rows as before")
    void plainTable_movesRowsOutOfDefault() {
        jdbcTemplate.execute("CREATE TABLE " + PLAIN_TABLE + " ("
                + " id bigint NOT NULL,"
                + " recorded_at timestamp NOT NULL"
                + ") PARTITION BY RANGE (recorded_at)");
        jdbcTemplate.execute("CREATE TABLE " + PLAIN_TABLE
                + "_default PARTITION OF " + PLAIN_TABLE + " DEFAULT");
        jdbcTemplate.update("INSERT INTO " + PLAIN_TABLE + " (id, recorded_at) VALUES (?, ?)",
                7L, java.sql.Timestamp.valueOf("2026-06-15 12:00:00"));

        Long moved = jdbcTemplate.queryForObject(
                "SELECT partition_ops.ensure_month_partition(?::regclass, ?::date)",
                Long.class, PLAIN_TABLE, "2026-06-01");

        assertThat(moved).isEqualTo(1L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT count(*) FROM " + PLAIN_TABLE + "_2026_06", Long.class)).isEqualTo(1L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT count(*) FROM " + PLAIN_TABLE + "_default", Long.class)).isZero();
    }
}
