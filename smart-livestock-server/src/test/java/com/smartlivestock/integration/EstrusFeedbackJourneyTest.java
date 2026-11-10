package com.smartlivestock.integration;

import com.smartlivestock.datagen.application.EvaluationService;
import com.smartlivestock.datagen.application.dto.EvaluationReport;
import com.smartlivestock.datagen.application.dto.MetricResult;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Estrus confirmation feedback journey (NIX-286 P2 Task 4, Testcontainers —
 * compile-only on machines without Docker; actual execution happens on the
 * remote testbed via
 * {@code scripts/remote-integration-test.sh --with-journey --target}).
 *
 * <p>Mirrors the {@link EstrusNormalizedScoringJourneyTest} fixture style:
 * raw SQL/entity inserts for livestock, device, installation, the ≥70-score
 * episode history and the candidate ESTRUS alert row — then the journey
 * entry, which here is the REAL HTTP surface
 * {@code POST /api/v1/farms/{farmId}/alerts/{alertId}/estrus-feedback}
 * (T2 controller). The endpoint is a JWT-domain route, so the journey uses
 * the seeded {@code ownerToken} from {@link AbstractJourneyTest} (OWNER role
 * satisfies the controller's {@code @PreAuthorize}) — no API-Key minting is
 * involved (that mechanism belongs to the open domain
 * {@code /api/v1/open/...} and its ownership-journey suite). Going through
 * HTTP proves the whole chain: role guard, controller request validation,
 * {@code SecurityContext} userId propagation ({@code created_by}/
 * {@code labeled_by}) and the service transaction against a real database
 * (fresh-DB Flyway chain including V20261111100000 — a passing run IS the
 * schema-validate proof).</p>
 *
 * <p><b>Episode fixture arithmetic.</b> The alert is created at
 * {@code alertAt − 1h}; the score history carries two ≥70 positions one hour
 * apart ({@code alertAt − 2h}, {@code alertAt − 1h}) plus one sub-threshold
 * position at {@code alertAt − 3h} (must NOT join the episode). The 24h
 * merge gap of {@code EstrusSeriesReplayer.mergeEpisodes} yields one episode
 * {@code [alertAt − 2h, alertAt − 1h]} covering the alert instant, so the
 * MANUAL label period must equal exactly that window.</p>
 *
 * <p><b>Contract note on rejection.</b> The T1 service writes the
 * ESTRUS_CONFIRM audit physiology row for BOTH verdicts (the note carries
 * "confirmed"/"rejected"); what differs is the label verdict/severity.
 * The rejection test therefore asserts the audit row exists at the storage
 * layer while the physiology record-card list ({@code listEvents}) never
 * surfaces it.</p>
 *
 * <p><b>Evaluation-skip assertion premise.</b> The evaluation report counts
 * labels over ALL active installations of the shared Testcontainers database.
 * No migration seeds ground-truth labels or anomaly scores, and this suite
 * is the verification target of {@code --target EstrusFeedbackJourneyTest}
 * (single-class run over a clean migrated DB), so within the evaluation
 * window the only verdict-bearing labels are the ones this test creates.</p>
 */
public class EstrusFeedbackJourneyTest extends AbstractJourneyTest {

    private static final long FARM_ID = 1L;
    private static final long TENANT_ID = 1L;
    private static final String OWNER_PHONE = "13800138000";
    /** Endpoint of the T2 controller (EstrusFeedbackController). */
    private static final String FEEDBACK_PATH = "/api/v1/farms/1/alerts/";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /** Real evaluation service — item 6 asserts its verdict filter against the live DB. */
    @Autowired
    private EvaluationService evaluationService;

    /** Fixed anchor: the whole fixture is defined by exact offsets from this instant. */
    private Instant alertAt;

    private final List<Long> livestockIds = new ArrayList<>();
    private final List<Long> deviceIds = new ArrayList<>();

    /** Unique suffixes so repeated runs never collide with seed codes. */
    private static final AtomicLong CODE_SEQ = new AtomicLong(System.currentTimeMillis() % 1_000_000);

    @BeforeEach
    void setUpFeedback() {
        alertAt = Instant.now().truncatedTo(ChronoUnit.HOURS);
    }

    @AfterEach
    void tearDownFeedback() {
        // Children first, then bindings, then devices and livestock (FK order).
        if (!livestockIds.isEmpty()) {
            Object[] livestockArgs = livestockIds.toArray();
            String livestockIn = placeholders(livestockIds.size());
            jdbcTemplate.update("DELETE FROM ground_truth_labels WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM physiology_events WHERE livestock_id IN (" + livestockIn + ")",
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
     * Journey 1: confirming a candidate alert writes, in ONE transaction, the
     * ALERT_CONFIRM/ESTRUS_CONFIRM audit row AND the MANUAL CONFIRMED label
     * whose period is the restored ≥70 episode — while the physiology
     * record-card list keeps hiding the audit-only row.
     */
    @Test
    void confirmWritesEventAndLabel() {
        long[] ids = insertHead("EF-A");
        long livestockId = ids[0];
        Instant alertCreated = alertAt.minus(Duration.ofHours(1));
        long alertId = insertEpisodeFixtureAndAlert(livestockId, alertCreated);
        long ownerUserId = ownerUserId();

        Map<String, Object> result = submitFeedback(alertId, true);

        // HTTP verdict payload (FeedbackResult).
        assertThat(result.get("verdict")).isEqualTo("CONFIRMED");
        assertThat(((Number) result.get("alertId")).longValue()).isEqualTo(alertId);
        assertThat(result.get("idempotent")).isEqualTo(false);
        assertThat(result.get("labelId")).isNotNull();
        assertThat(result.get("physiologyEventId")).isNotNull();

        // Audit-only physiology row: ALERT_CONFIRM source, ref to the alert,
        // attributed to the authenticated owner through the HTTP chain.
        long eventRows = count("SELECT COUNT(*) FROM physiology_events "
                + "WHERE livestock_id = ? AND ref_id = ? AND source = 'ALERT_CONFIRM' "
                + "AND event_type = 'ESTRUS_CONFIRM'", livestockId, alertId);
        assertThat(eventRows).isEqualTo(1L);
        Map<String, Object> event = jdbcTemplate.queryForMap(
                "SELECT created_by, occurred_at, note FROM physiology_events "
                        + "WHERE livestock_id = ? AND ref_id = ? AND source = 'ALERT_CONFIRM'",
                livestockId, alertId);
        assertThat(((Number) event.get("created_by")).longValue()).isEqualTo(ownerUserId);
        assertThat(instantOf(event.get("occurred_at"))).isEqualTo(alertCreated);
        assertThat((String) event.get("note")).contains("confirmed");

        // MANUAL ground-truth label: ESTRUS / CONFIRMED / severity 1.0 with
        // the restored episode bounds as its period.
        Map<String, Object> label = jdbcTemplate.queryForMap(
                "SELECT type, source, verdict, ref_alert_id, severity, period_start, period_end, labeled_by "
                        + "FROM ground_truth_labels WHERE ref_alert_id = ?", alertId);
        // The type column stores the ScenarioType dbValue ("estrus"), not the enum name.
        assertThat(label.get("type")).isEqualTo(ScenarioType.ESTRUS.getDbValue());
        assertThat(label.get("source")).isEqualTo("MANUAL");
        assertThat(label.get("verdict")).isEqualTo("CONFIRMED");
        assertThat(((Number) label.get("ref_alert_id")).longValue()).isEqualTo(alertId);
        assertThat(asBigDecimal(label.get("severity"))).isEqualByComparingTo("1.00");
        assertThat(instantOf(label.get("period_start"))).isEqualTo(alertAt.minus(Duration.ofHours(2)));
        assertThat(instantOf(label.get("period_end"))).isEqualTo(alertAt.minus(Duration.ofHours(1)));
        assertThat(((Number) label.get("labeled_by")).longValue()).isEqualTo(ownerUserId);

        // The physiology record card never shows the ESTRUS_CONFIRM audit row.
        Map<String, Object> list = getApi(ownerToken,
                "/api/v1/farms/1/livestock/" + livestockId + "/physiology-events");
        List<Map<String, Object>> items = getItems(list);
        assertThat(items).isEmpty();
    }

    /**
     * Journey 2: rejecting the candidate writes a REJECTED / severity 0.0
     * label; with no ≥70 score history the label period collapses to the
     * alert point window. The audit row is still written at the storage
     * layer (both verdicts audit — see class javadoc) but the record card
     * never surfaces it.
     */
    @Test
    void rejectionWritesRejectedLabel() {
        long[] ids = insertHead("EF-B");
        long livestockId = ids[0];
        Instant alertCreated = alertAt;
        // No estrus_scores rows → episode restore finds nothing → point window.
        long alertId = insertEstrusAlert(livestockId, alertCreated);

        Map<String, Object> result = submitFeedback(alertId, false);

        assertThat(result.get("verdict")).isEqualTo("REJECTED");
        assertThat(result.get("idempotent")).isEqualTo(false);
        assertThat(result.get("labelId")).isNotNull();
        assertThat(result.get("physiologyEventId")).isNotNull();

        Map<String, Object> label = jdbcTemplate.queryForMap(
                "SELECT type, source, verdict, ref_alert_id, severity, period_start, period_end "
                        + "FROM ground_truth_labels WHERE ref_alert_id = ?", alertId);
        assertThat(label.get("type")).isEqualTo(ScenarioType.ESTRUS.getDbValue());
        assertThat(label.get("source")).isEqualTo("MANUAL");
        assertThat(label.get("verdict")).isEqualTo("REJECTED");
        assertThat(asBigDecimal(label.get("severity"))).isEqualByComparingTo("0.00");
        assertThat(instantOf(label.get("period_start"))).isEqualTo(alertCreated);
        assertThat(instantOf(label.get("period_end"))).isEqualTo(alertCreated);

        // The audit row exists for both verdicts (note distinguishes them).
        Map<String, Object> event = jdbcTemplate.queryForMap(
                "SELECT note FROM physiology_events "
                        + "WHERE livestock_id = ? AND ref_id = ? AND source = 'ALERT_CONFIRM'",
                livestockId, alertId);
        assertThat((String) event.get("note")).contains("rejected");

        // And the card list stays clean either way.
        Map<String, Object> list = getApi(ownerToken,
                "/api/v1/farms/1/livestock/" + livestockId + "/physiology-events");
        assertThat(getItems(list)).isEmpty();
    }

    /**
     * Journey 3: flipping the verdict supersedes the old label row and
     * inserts the new one in the same transaction — under
     * {@code uq_gt_labels_alert_active} exactly one CONFIRMED/REJECTED row
     * stays effective (the flip's REJECTED), everything older is SUPERSEDED;
     * the audit physiology row is reused, not duplicated.
     */
    @Test
    void flipSupersedesAndKeepsHistory() {
        long[] ids = insertHead("EF-C");
        long livestockId = ids[0];
        Instant alertCreated = alertAt.minus(Duration.ofHours(1));
        long alertId = insertEpisodeFixtureAndAlert(livestockId, alertCreated);

        Map<String, Object> confirm = submitFeedback(alertId, true);
        Map<String, Object> reject = submitFeedback(alertId, false);

        assertThat(confirm.get("verdict")).isEqualTo("CONFIRMED");
        assertThat(reject.get("verdict")).isEqualTo("REJECTED");
        assertThat(reject.get("idempotent")).isEqualTo(false);
        // A flip writes a NEW label row (new id), never a no-op.
        assertThat(reject.get("labelId")).isNotEqualTo(confirm.get("labelId"));

        // History kept, exactly one effective ruling.
        assertThat(verdictCount(alertId, "CONFIRMED")).isEqualTo(0L);
        assertThat(verdictCount(alertId, "REJECTED")).isEqualTo(1L);
        assertThat(verdictCount(alertId, "SUPERSEDED")).isEqualTo(1L);
        assertThat(labelCount(alertId)).isEqualTo(2L);
        Map<String, Object> effective = jdbcTemplate.queryForMap(
                "SELECT severity FROM ground_truth_labels "
                        + "WHERE ref_alert_id = ? AND verdict = 'REJECTED'", alertId);
        assertThat(asBigDecimal(effective.get("severity"))).isEqualByComparingTo("0.00");

        // The audit row was reused: still exactly one ESTRUS_CONFIRM row.
        long eventRows = count("SELECT COUNT(*) FROM physiology_events "
                + "WHERE livestock_id = ? AND ref_id = ? AND source = 'ALERT_CONFIRM' "
                + "AND event_type = 'ESTRUS_CONFIRM'", livestockId, alertId);
        assertThat(eventRows).isEqualTo(1L);
    }

    /**
     * Journey 4: re-submitting the SAME verdict is a no-op — no new label
     * row, no new audit row, same ids echoed back with {@code idempotent=true}.
     */
    @Test
    void idempotentRepeatNoNewRows() {
        long[] ids = insertHead("EF-D");
        long livestockId = ids[0];
        Instant alertCreated = alertAt.minus(Duration.ofHours(1));
        long alertId = insertEpisodeFixtureAndAlert(livestockId, alertCreated);

        Map<String, Object> first = submitFeedback(alertId, true);
        Map<String, Object> second = submitFeedback(alertId, true);

        assertThat(first.get("verdict")).isEqualTo("CONFIRMED");
        assertThat(first.get("idempotent")).isEqualTo(false);
        assertThat(second.get("verdict")).isEqualTo("CONFIRMED");
        assertThat(second.get("idempotent")).isEqualTo(true);
        assertThat(second.get("labelId")).isEqualTo(first.get("labelId"));
        assertThat(second.get("physiologyEventId")).isEqualTo(first.get("physiologyEventId"));

        // Counters unchanged by the repeat.
        assertThat(labelCount(alertId)).isEqualTo(1L);
        long eventRows = count("SELECT COUNT(*) FROM physiology_events "
                + "WHERE livestock_id = ? AND ref_id = ? AND source = 'ALERT_CONFIRM' "
                + "AND event_type = 'ESTRUS_CONFIRM'", livestockId, alertId);
        assertThat(eventRows).isEqualTo(1L);
    }

    /**
     * Journey 5: committing a BREEDING event auto-derives a weak-evidence
     * (verdict-less) BREEDING_DERIVED label for the candidate alert raised
     * inside the 48h lookback window — and re-recording the same breeding
     * (idempotent event path) never duplicates the derived row.
     */
    @Test
    void breedingLinksDerivedLabels() {
        long[] ids = insertHead("EF-E");
        long livestockId = ids[0];
        // Mirror PhysiologyEventService.parseOccurredAt: "yyyy-MM-dd" is
        // anchored at Asia/Shanghai midnight; the candidate alert was raised
        // 1h before that instant → inside the 48h breeding lookback window.
        Instant breedingAt = LocalDate.now(ZoneId.of("Asia/Shanghai"))
                .atStartOfDay(ZoneId.of("Asia/Shanghai")).toInstant();
        Instant alertCreated = breedingAt.minus(Duration.ofHours(1));
        long alertId = insertEstrusAlert(livestockId, alertCreated);

        Map<String, Object> event = postApi(ownerToken,
                "/api/v1/farms/1/livestock/" + livestockId + "/physiology-events",
                Map.of("eventType", "BREEDING",
                        "occurredAt", LocalDate.now(ZoneId.of("Asia/Shanghai")).toString(),
                        "note", "journey breeding record"));
        assertThat(event.get("eventType")).isEqualTo("BREEDING");

        Map<String, Object> derived = jdbcTemplate.queryForMap(
                "SELECT type, source, verdict, ref_alert_id, severity, period_start, period_end "
                        + "FROM ground_truth_labels "
                        + "WHERE ref_alert_id = ? AND source = 'BREEDING_DERIVED'", alertId);
        assertThat(derived.get("type")).isEqualTo(ScenarioType.ESTRUS.getDbValue());
        assertThat(derived.get("verdict")).isNull();
        assertThat(((Number) derived.get("ref_alert_id")).longValue()).isEqualTo(alertId);
        assertThat(asBigDecimal(derived.get("severity"))).isEqualByComparingTo("0.00");
        assertThat(instantOf(derived.get("period_start"))).isEqualTo(alertCreated);
        assertThat(instantOf(derived.get("period_end"))).isEqualTo(alertCreated);

        // Re-recording the same breeding day: the manual event is idempotent
        // (same livestock/type/occurred_at/MANUAL row), so the fresh-insert
        // linking hook does not run again — the derived row stays unique.
        postApi(ownerToken,
                "/api/v1/farms/1/livestock/" + livestockId + "/physiology-events",
                Map.of("eventType", "BREEDING",
                        "occurredAt", LocalDate.now(ZoneId.of("Asia/Shanghai")).toString(),
                        "note", "journey breeding record"));
        assertThat(count("SELECT COUNT(*) FROM ground_truth_labels "
                + "WHERE ref_alert_id = ? AND source = 'BREEDING_DERIVED'", alertId))
                .isEqualTo(1L);
    }

    /**
     * Journey 6 (verdict filter on the real query path): the evaluation
     * aggregation skips REJECTED rows (human-denied false positives) while
     * CONFIRMED rows still participate. With no anomaly scores in the window,
     * the confirmed animal lands as labeled-but-unscored (one false negative)
     * and the rejected animal contributes nothing — totalLabels 1, one ESTRUS
     * metric row with falseNegative=1. Premise: single-class run over the
     * clean migrated DB (see class javadoc).
     */
    @Test
    void evaluationSkipsRejected() {
        long[] cowA = insertHead("EF-F1");
        long alertA = insertEstrusAlert(cowA[0], alertAt);
        submitFeedback(alertA, false); // REJECTED — must be skipped

        long[] cowB = insertHead("EF-F2");
        long alertB = insertEstrusAlert(cowB[0], alertAt);
        submitFeedback(alertB, true); // CONFIRMED — must participate

        EvaluationReport report = evaluationService.evaluate(
                alertAt.minus(Duration.ofDays(1)), alertAt.plus(Duration.ofDays(1)), 50.0);

        // No anomaly scores seeded → the scoredHigh side is empty everywhere.
        assertThat(report.totalScores()).isEqualTo(0);
        // Only the CONFIRMED label counts; the REJECTED one is filtered out.
        assertThat(report.totalLabels()).isEqualTo(1);
        assertThat(report.healthPerPattern()).hasSize(1);
        MetricResult estrus = report.healthPerPattern().get(0);
        assertThat(estrus.type()).isEqualTo(ScenarioType.ESTRUS);
        // CONFIRMED animal: labeled abnormal, never scored high → fn.
        assertThat(estrus.falseNegative()).isEqualTo(1);
        assertThat(estrus.truePositive()).isEqualTo(0);
        assertThat(estrus.falsePositive()).isEqualTo(0);
    }

    // ── Fixture helpers (EstrusNormalizedScoringJourneyTest pattern) ──

    /** Minimal livestock + ACTIVE capsule device + open installation row. */
    private long[] insertHead(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "EF-LIVE-" + tag + "-" + seq;
        String deviceCode = "EF-DEV-" + tag + "-" + seq;

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
     * Episode fixture (arithmetic in the class javadoc): sub-threshold score
     * at −3h, two ≥70 scores at −2h/−1h merging into one episode, and the
     * candidate alert created at the episode end.
     */
    private long insertEpisodeFixtureAndAlert(long livestockId, Instant alertCreated) {
        insertScore(livestockId, 60, alertAt.minus(Duration.ofHours(3)));
        insertScore(livestockId, 85, alertAt.minus(Duration.ofHours(2)));
        insertScore(livestockId, 78, alertAt.minus(Duration.ofHours(1)));
        return insertEstrusAlert(livestockId, alertCreated);
    }

    /** One estrus_scores row (score CHECK 0..100 honored by the callers). */
    private void insertScore(long livestockId, int score, Instant scoredAt) {
        jdbcTemplate.update(
                "INSERT INTO estrus_scores (farm_id, livestock_id, score, scored_at) VALUES (?, ?, ?, ?)",
                FARM_ID, livestockId, score, Timestamp.from(scoredAt));
    }

    /**
     * One candidate ESTRUS alert row. CHECK domains follow the CURRENT
     * constraint set, not V2: V26 (alert notification model) rebuilt
     * chk_alerts_status to ('ACTIVE','DISMISSED','AUTO_RESOLVED') and kept
     * 'ESTRUS' inside chk_alerts_type.
     */
    private long insertEstrusAlert(long livestockId, Instant createdAt) {
        jdbcTemplate.update(
                "INSERT INTO alerts (farm_id, livestock_id, type, status, severity, message, created_at) "
                        + "VALUES (?, ?, 'ESTRUS', 'ACTIVE', 'WARNING', ?, ?)",
                FARM_ID, livestockId, "journey candidate estrus alert", Timestamp.from(createdAt));
        return jdbcTemplate.queryForObject(
                "SELECT id FROM alerts WHERE livestock_id = ? ORDER BY id DESC LIMIT 1",
                Long.class, livestockId);
    }

    /** The production entry: the T2 HTTP endpoint with the seeded owner JWT. */
    private Map<String, Object> submitFeedback(long alertId, boolean confirmed) {
        return postApi(ownerToken, FEEDBACK_PATH + alertId + "/estrus-feedback",
                Map.of("confirmed", confirmed));
    }

    /**
     * Id of the seeded OWNER. Since V20261015100000 (always part of the
     * fresh-DB chain) bare 11-digit CN numbers are normalized to E.164, the
     * stored phone is "+86 13800138000".
     */
    private long ownerUserId() {
        Long id = jdbcTemplate.queryForObject(
                "SELECT id FROM users WHERE phone = ?", Long.class, "+86" + OWNER_PHONE);
        assertThat(id).isNotNull();
        return id;
    }

    private static String placeholders(int count) {
        return String.join(",", java.util.Collections.nCopies(count, "?"));
    }

    // ── Assertion helpers ────────────────────────────────────────

    private long count(String sql, Object... args) {
        Long value = jdbcTemplate.queryForObject(sql, Long.class, args);
        return value == null ? 0L : value;
    }

    private long verdictCount(long alertId, String verdict) {
        return count("SELECT COUNT(*) FROM ground_truth_labels "
                + "WHERE ref_alert_id = ? AND verdict = ?", alertId, verdict);
    }

    private long labelCount(long alertId) {
        return count("SELECT COUNT(*) FROM ground_truth_labels WHERE ref_alert_id = ?", alertId);
    }

    /**
     * TIMESTAMP columns round-trip through {@code java.sql.Timestamp} in the
     * JVM's default zone on BOTH write paths (JdbcTemplate fixture inserts
     * and Hibernate {@code Instant} persistence), so {@code toInstant()}
     * restores the exact epoch millis this test wrote.
     */
    private static Instant instantOf(Object dbValue) {
        assertThat(dbValue).isNotNull();
        return ((Timestamp) dbValue).toInstant();
    }

    private static BigDecimal asBigDecimal(Object dbValue) {
        assertThat(dbValue).isNotNull();
        return new BigDecimal(dbValue.toString());
    }
}
