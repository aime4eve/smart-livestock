package com.smartlivestock.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.application.CalvingPredictionScheduler;
import com.smartlivestock.health.infrastructure.persistence.entity.ActivityLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.ActivityLogJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Calving prediction journey (NIX-381 plan 2026-11-06 Task 5, Testcontainers —
 * compile-only on machines without Docker; actual execution happens on the
 * remote testbed via
 * {@code scripts/remote-integration-test.sh --with-journey --target}).
 *
 * <p>End-to-end path through the REAL production entry point
 * {@link CalvingPredictionScheduler#evaluateActiveLivestock()} (recently-active
 * enumeration → per-head REQUIRES_NEW evaluation → feature gate with the
 * explicit tenant resolution → kernel scoring → calving_predictions row +
 * targeted health_snapshots.calving_risk_score UPDATE → CALVING_WARNING
 * ticket), asserted against the database only — nothing is mocked.</p>
 *
 * <p>Oracle fixture (PREPARTUM head): temperature flat 39.00 until T−24h, then
 * a linear decline 39.00 → 38.70 over the last 24h (30-minute granularity) —
 * the measured 6h-window drop vs the same-phase pooled reference is 0.27
 * (tempScore 70); activity flat 1.00 with the last 8h at 1.50 (ratio 1.50,
 * activityScore 100). With a MANUAL BREEDING record 281 days old the prior is
 * NORMAL (100) and the composite is 0.45×70 + 0.35×100 + 0.20×100 = 86.5 → 87;
 * without a record the weights renormalize to 83. Both cross the alert line.
 * A drinking valley (35.00 × 6 samples) sits inside a drinking_events window
 * far from every scored window — the exclusion path must run without killing
 * the signal. The onset scan detects the decline at T−9h (drop reaches 0.15
 * there and 0.15 ÷ slope), so the estimated window is [T−7h, T+21h] (28h
 * span) and the ticket message carries
 * {@code alert.health.calving.evidence.withPrior.withWindow} — score plus the
 * three evidence channels (temperature change, activity multiple, 281 breeding
 * days) plus the window, six frozen messageArgs.</p>
 *
 * <p>Alert-state semantics (alertPersistencePoints = 2): the FIRST at-threshold
 * evaluation only lands the score; the SECOND consecutive one raises the
 * ticket; a third finds the ACTIVE ticket and deduplicates; a sub-release
 * score resolves the ticket immediately and clears the column. Steady-state
 * low scores write nothing.</p>
 *
 * <p>The datagen synthesis tick runner is disabled for this context
 * ({@code datagen.enabled=false} via {@code @DynamicPropertySource}, the
 * {@link SimulationEvaluationJourneyTest} precedent): the V38 migration seeds
 * a RUNNING synthesis scenario that would otherwise ingest telemetry between
 * fixture and evaluation.</p>
 *
 * <p>Working point pinned (Task 7d): the oracle above was hand-computed on the
 * pre-calibration defaults — 6h temperature window (so the read span is
 * 24 + 48 + 6 = 78h, matching the fixture) and weights 0.45 / 0.35 / 0.20.
 * The same {@code @DynamicPropertySource} pins exactly those keys, because this
 * journey verifies the pipeline, the alert state machine and the alert, not the
 * calibrated values; the calibrated defaults (plan 7d: 24h window,
 * 0.35 / 0.45 / 0.20, rebound off) would move the score and the onset. The
 * rebound switch keeps its default: no fixture here ever rebounds.</p>
 */
public class CalvingPredictionJourneyTest extends AbstractJourneyTest {

    private static final long FARM_ID = 1L;
    private static final long TENANT_ID = 1L;
    private static final BigDecimal FLAT_TEMP = new BigDecimal("39.00");
    private static final BigDecimal VALLEY_TEMP = new BigDecimal("35.00");
    private static final BigDecimal BASELINE_TEMP = new BigDecimal("38.50");
    /** Learned-baseline stamp planted on the audited head's snapshot row. */
    private static final BigDecimal LEARNED_BASELINE = new BigDecimal("38.75");

    @Autowired
    private CalvingPredictionScheduler calvingScheduler;

    @Autowired
    private TemperatureLogJpaRepository temperatureLogRepository;

    @Autowired
    private ActivityLogJpaRepository activityLogRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private final List<Long> livestockIds = new ArrayList<>();
    private final List<Long> deviceIds = new ArrayList<>();

    /** Subscription row snapshot (gate scenario flips it; restored after). */
    private String originalTier;
    private String originalStatus;
    private Timestamp originalTrialEndsAt;
    private boolean subscriptionFlipped;

    /** Unique suffixes so repeated runs never collide with seed codes. */
    private static final AtomicLong CODE_SEQ = new AtomicLong(System.currentTimeMillis() % 1_000_000);

    @DynamicPropertySource
    static void disableSynthesisTick(DynamicPropertyRegistry registry) {
        // Kill the background synthesis tick (see class javadoc) — the calving
        // scheduler itself is a plain @Scheduled bean and stays active.
        registry.add("datagen.enabled", () -> "false");
        // Oracle working point (see class javadoc): the pre-7d 6h window and
        // 0.45/0.35/0.20 weights. The rebound switch is left at its default
        // (irrelevant to every fixture here: a monotonic decline or a flat
        // series never rebounds).
        registry.add("smartlivestock.calving.current-temp-window-hours", () -> "6");
        registry.add("smartlivestock.calving.weight-temp-drop", () -> "0.45");
        registry.add("smartlivestock.calving.weight-activity", () -> "0.35");
        registry.add("smartlivestock.calving.weight-prior", () -> "0.20");
    }

    @BeforeEach
    void setUpCalving() {
        Map<String, Object> sub = jdbcTemplate.queryForMap(
                "SELECT tier, status, trial_ends_at FROM subscriptions WHERE tenant_id = ?", TENANT_ID);
        originalTier = (String) sub.get("tier");
        originalStatus = (String) sub.get("status");
        originalTrialEndsAt = (Timestamp) sub.get("trial_ends_at");
        subscriptionFlipped = false;
    }

    @AfterEach
    void tearDownCalving() {
        restoreSubscription();
        // Children first, then bindings, then devices and livestock (FK order).
        // calving_predictions carries no livestock FK (estrus_scores style) but
        // is deleted before livestock anyway; signal_event_outbox rows reference
        // only the farm and are left alone (journey-wide precedent).
        if (!livestockIds.isEmpty()) {
            Object[] livestockArgs = livestockIds.toArray();
            String livestockIn = placeholders(livestockIds.size());
            jdbcTemplate.update("DELETE FROM calving_predictions WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM alerts WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM temperature_logs WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM activity_logs WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM drinking_events WHERE livestock_id IN (" + livestockIn + ")",
                    livestockArgs);
            jdbcTemplate.update("DELETE FROM physiology_events WHERE livestock_id IN (" + livestockIn + ")",
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

    // ── Scenario 1: high-risk head — full detect chain ────────────────

    /**
     * PREPARTUM head (LEARNED snapshot audit) through the real scheduler:
     * the first poll lands the 87 score (persistence rule — no ticket yet),
     * the second consecutive at-threshold poll raises exactly one
     * CALVING_WARNING ticket and stamps the prediction rows with the head's
     * LEARNED baseline audit values.
     */
    @Test
    void highRiskHead_detectedThroughRealScheduler() throws Exception {
        Head headA = createHead("CPA");
        stampLearnedSnapshot(headA);
        insertPrepartumSeries(headA, "AGENTIC_PLATFORM");
        insertBreedingRecord(headA, 281);

        // Poll 1: first crossing only lands the score (alertPersistencePoints=2).
        pollScheduler();
        List<Map<String, Object>> rows = calvingPredictions(headA.livestockId());
        assertThat(rows).hasSize(1);
        assertThat(score(rows.get(0))).isEqualTo(87);
        assertThat(score(rows.get(0))).isGreaterThanOrEqualTo(70);
        assertThat(snapshotCalvingScore(headA.livestockId())).isEqualTo(87);
        assertThat(calvingTickets(headA.livestockId())).isEmpty();

        // Poll 2: prev 87 >= 70 and new 87 >= 70 → crossed → raise.
        pollScheduler();
        rows = calvingPredictions(headA.livestockId());
        assertThat(rows).hasSize(2);
        assertThat(rows).allSatisfy(row -> {
            assertThat(score(row)).isEqualTo(87);
            // Audit stamp: the head's snapshot is LEARNED → the rows carry it.
            assertThat(row.get("baseline_source")).isEqualTo("LEARNED");
            assertThat(new BigDecimal(row.get("baseline_used").toString()))
                    .isEqualByComparingTo(LEARNED_BASELINE);
            assertThat(row.get("baseline_computed_at")).isNotNull();
            assertThat(row.get("baseline_algorithm_version")).isEqualTo("V1");
            // The 281-day BREEDING record fed this evaluation.
            assertThat(row.get("prior_enabled")).isEqualTo(Boolean.TRUE);
            // Onset path: [onset+2h, onset+30h] — a 28h estimated window.
            assertThat(row.get("expected_window_start")).isNotNull();
            assertThat(row.get("expected_window_end")).isNotNull();
            long spanMinutes = Duration.between(
                    instant(row.get("expected_window_start")), instant(row.get("expected_window_end")))
                    .toMinutes();
            assertThat(spanMinutes).isEqualTo(Duration.ofHours(28).toMinutes());
        });

        // Snapshot column stamped with the alert-grade score.
        Integer snap = snapshotCalvingScore(headA.livestockId());
        assertThat(snap).isNotNull();
        assertThat(snap).isGreaterThanOrEqualTo(70);

        // Exactly one ACTIVE ticket, WARNING severity, RULE source, evidence key.
        List<Map<String, Object>> tickets = calvingTickets(headA.livestockId());
        assertThat(tickets).hasSize(1);
        Map<String, Object> ticket = tickets.get(0);
        assertThat(ticket.get("status")).isEqualTo("ACTIVE");
        assertThat(ticket.get("severity")).isEqualTo("WARNING");
        assertThat(ticket.get("source")).isEqualTo("RULE");
        assertThat(ticket.get("message_key"))
                .isEqualTo("alert.health.calving.evidence.withPrior.withWindow");
        // Frozen evidence args: [code, score, tempDrop, activityRatio,
        // gestationDays, window] — six slots with the 281-day prior disclosed.
        Object[] args = new ObjectMapper().readValue((String) ticket.get("message_args"), Object[].class);
        assertThat(args).hasSize(6);
        assertThat(args[1]).isEqualTo("87");
        assertThat(args[4]).isEqualTo("281");
    }

    // ── Scenario 2: repeated evaluation does not duplicate the ticket ──

    /**
     * A third consecutive at-threshold poll crosses again but the raise is
     * deduplicated against the ACTIVE ticket: still exactly one ACTIVE
     * CALVING_WARNING row, while every evaluation keeps writing its history
     * row (crossed evaluations persist).
     */
    @Test
    void repeatedEvaluation_deduplicatesTicket() {
        Head headC = createHead("CPC");
        insertPrepartumSeries(headC, "AGENTIC_PLATFORM");
        insertBreedingRecord(headC, 281);

        pollScheduler(); // lands the score
        pollScheduler(); // raises the ticket
        assertThat(calvingTickets(headC.livestockId())).hasSize(1);

        pollScheduler(); // crossed again, but deduplicated
        List<Map<String, Object>> tickets = calvingTickets(headC.livestockId());
        assertThat(tickets).hasSize(1);
        assertThat(tickets.get(0).get("status")).isEqualTo("ACTIVE");

        assertThat(calvingPredictions(headC.livestockId())).hasSize(3);
        assertThat(snapshotCalvingScore(headC.livestockId())).isEqualTo(87);
    }

    // ── Scenario 3: risk fall releases the ticket and clears the column ──

    /**
     * Dedicated release-path head: preset prev=75 in the snapshot column and
     * a preset ACTIVE CALVING_WARNING ticket (the state a raised head
     * carries), then a flat low-risk series drives the score to 0 — below the
     * 55 release line → the ticket turns AUTO_RESOLVED (resolved_type AUTO),
     * the targeted UPDATE clears the column to NULL and one history row
     * records the release score.
     */
    @Test
    void riskFall_releasesTicketAndClearsColumn() {
        Head headD = createHead("CPD");
        presetSnapshotCalvingScore(headD, 75);
        insertFlatSeries(headD, "AGENTIC_PLATFORM");
        insertActiveCalvingTicket(headD);
        assertThat(calvingTickets(headD.livestockId())).hasSize(1);

        pollScheduler(); // release is immediate (no persistence requirement)

        List<Map<String, Object>> tickets = calvingTickets(headD.livestockId());
        assertThat(tickets).hasSize(1);
        assertThat(tickets.get(0).get("status")).isEqualTo("AUTO_RESOLVED");
        assertThat(tickets.get(0).get("resolved_type")).isEqualTo("AUTO");
        assertThat(tickets.get(0).get("resolved_at")).isNotNull();

        // Targeted UPDATE cleared the column (NULL = released/never scored).
        assertThat(snapshotCalvingScore(headD.livestockId())).isNull();

        List<Map<String, Object>> rows = calvingPredictions(headD.livestockId());
        assertThat(rows).hasSize(1);
        assertThat(score(rows.get(0))).isZero();
    }

    // ── Scenario 4: low-risk head — steady state writes nothing ────────

    /**
     * Flat 39.00 / flat activity head scores 0 (both channels available but
     * silent): no prediction row, no ticket, snapshot column untouched across
     * two polls.
     */
    @Test
    void lowRiskHead_writesNothing() {
        Head headB = createHead("CPB");
        insertFlatSeries(headB, "AGENTIC_PLATFORM");

        pollScheduler();
        pollScheduler();

        assertThat(calvingPredictions(headB.livestockId())).isEmpty();
        assertThat(calvingTickets(headB.livestockId())).isEmpty();
        assertThat(snapshotCalvingScore(headB.livestockId())).isNull();
    }

    // ── Scenario 5: locked feature gate skips the evaluation ───────────

    /**
     * With tenant 1's subscription downgraded to an active BASIC tier (no
     * trial → effectiveTier BASIC → calving_warning gate locked) the same
     * high-risk head is skipped before any read or write: zero rows, zero
     * tickets, snapshot column untouched. The scheduler thread has no
     * TenantContext — the explicit-tenant gate resolution is exactly what is
     * under test here.
     */
    @Test
    void lockedGate_skipsEvaluation() {
        Head headE = createHead("CPE");
        insertPrepartumSeries(headE, "AGENTIC_PLATFORM");
        insertBreedingRecord(headE, 281);

        jdbcTemplate.update(
                "UPDATE subscriptions SET tier = 'basic', status = 'active', trial_ends_at = NULL "
                        + "WHERE tenant_id = ?",
                TENANT_ID);
        subscriptionFlipped = true;
        try {
            pollScheduler();
            pollScheduler();

            assertThat(calvingPredictions(headE.livestockId())).isEmpty();
            assertThat(calvingTickets(headE.livestockId())).isEmpty();
            assertThat(snapshotCalvingScore(headE.livestockId())).isNull();
        } finally {
            restoreSubscription();
            subscriptionFlipped = false;
        }
    }

    // ── Scenario 6: ticket source follows the telemetry source ─────────

    /**
     * Truth-line: synthetic telemetry must never pass for a real rule alert.
     * Two identical PREPARTUM heads, one with AGENTIC_PLATFORM logs (its
     * ticket maps to RULE) and one with DATAGEN logs (the ticket keeps
     * DATAGEN). The DATAGEN head's rows also carry the DEFAULT baseline audit
     * stamp (38.50, no computed-at, no version) — the counterpart of
     * scenario 1's LEARNED stamp.
     */
    @Test
    void ticketSource_followsTelemetrySource() {
        Head ruleHead = createHead("CPR");
        insertPrepartumSeries(ruleHead, "AGENTIC_PLATFORM");
        Head datagenHead = createHead("CPG");
        insertPrepartumSeries(datagenHead, "DATAGEN");

        pollScheduler(); // land scores
        pollScheduler(); // raise both tickets
        pollScheduler(); // deduplicated re-cross

        List<Map<String, Object>> ruleTickets = calvingTickets(ruleHead.livestockId());
        assertThat(ruleTickets).hasSize(1);
        assertThat(ruleTickets.get(0).get("status")).isEqualTo("ACTIVE");
        assertThat(ruleTickets.get(0).get("source")).isEqualTo("RULE");

        List<Map<String, Object>> datagenTickets = calvingTickets(datagenHead.livestockId());
        assertThat(datagenTickets).hasSize(1);
        assertThat(datagenTickets.get(0).get("status")).isEqualTo("ACTIVE");
        assertThat(datagenTickets.get(0).get("source")).isEqualTo("DATAGEN");

        // DEFAULT-side audit stamp on the bare-snapshot head.
        List<Map<String, Object>> datagenRows = calvingPredictions(datagenHead.livestockId());
        assertThat(datagenRows).isNotEmpty();
        assertThat(datagenRows).allSatisfy(row -> {
            assertThat(row.get("baseline_source")).isEqualTo("DEFAULT");
            assertThat(new BigDecimal(row.get("baseline_used").toString()))
                    .isEqualByComparingTo(BASELINE_TEMP);
            assertThat(row.get("baseline_computed_at")).isNull();
            assertThat(row.get("baseline_algorithm_version")).isNull();
        });
    }

    // ── Fixture helpers (IndividualBaselineLearningJourneyTest style) ──

    private record Head(Long livestockId, Long deviceId) {
    }

    /** Minimal livestock + ACTIVE capsule device + open installation + bare snapshot row. */
    private Head createHead(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "CP-LIVE-" + tag + "-" + seq;
        String deviceCode = "CP-DEV-" + tag + "-" + seq;

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
        // Bare row: every other column is a DB default (incl. DEFAULT/38.50).
        jdbcTemplate.update(
                "INSERT INTO health_snapshots (livestock_id, farm_id) VALUES (?, ?)",
                livestockId, FARM_ID);
        livestockIds.add(livestockId);
        deviceIds.add(deviceId);
        return new Head(livestockId, deviceId);
    }

    /** Turns the head's bare snapshot into a learned-baseline one (audit-stamp fixture). */
    private void stampLearnedSnapshot(Head head) {
        jdbcTemplate.update(
                "UPDATE health_snapshots SET baseline_source = 'LEARNED', baseline_temp = ?, "
                        + "baseline_computed_at = NOW(), baseline_algorithm_version = 'V1' WHERE livestock_id = ?",
                LEARNED_BASELINE, head.livestockId());
    }

    /** Presets the snapshot column (the raised-state fixture of the release path). */
    private void presetSnapshotCalvingScore(Head head, int score) {
        jdbcTemplate.update(
                "UPDATE health_snapshots SET calving_risk_score = ? WHERE livestock_id = ?",
                score, head.livestockId());
    }

    /**
     * The PREPARTUM oracle series at 30-minute granularity (all instants
     * relative to the fixture instant; the half-open production windows make
     * the membership stable against sub-minute drift):
     * <ul>
     *   <li>temperature flat 39.00 from T−78h (the 78h read span) to T−24.5h,
     *       with a 6-sample 35.00 drinking valley over [T−70h, T−67.5h] that a
     *       drinking_events row (descent T−70h, trough T−69h → buffered
     *       exclusion [T−70h, T−67h)) removes;</li>
     *   <li>temperature linear 39.00 → 38.70 over [T−24h, T) (sample j of 47
     *       at T−24h + j·30min → 39.00 − 0.30·j/47);</li>
     *   <li>activity flat 1.00 from T−56h to T−8.5h, then 1.50 through T−0.5h.</li>
     * </ul>
     */
    private void insertPrepartumSeries(Head head, String source) {
        Instant t = Instant.now();

        // Temperature: [T−78h, T−24.5h] flat with the valley swapped in.
        for (int k = 0; k <= 107; k++) {
            double hoursAgo = 78 - 0.5 * k;
            boolean valley = hoursAgo >= 67.5 && hoursAgo <= 70; // T−70h .. T−67.5h
            insertTemp(head, minus(t, hoursAgo), valley ? VALLEY_TEMP : FLAT_TEMP, source);
        }
        // Decline: T−24h + j·30min, j = 0..47 (sample at T itself excluded by
        // the half-open windows, so the last planted sample is at T−0.5h).
        // Stored at the column scale (2dp) — the kernel reads exactly these.
        for (int j = 0; j <= 47; j++) {
            BigDecimal value = FLAT_TEMP.subtract(
                            new BigDecimal("0.30").multiply(BigDecimal.valueOf(j))
                                    .divide(BigDecimal.valueOf(47), MathContext.DECIMAL64))
                    .setScale(2, RoundingMode.HALF_UP);
            insertTemp(head, minus(t, 24 - 0.5 * j), value, source);
        }
        // Drinking event the exclusion fetch must consume (buffered window
        // [T−70h, T−67h) covers every valley sample).
        jdbcTemplate.update(
                "INSERT INTO drinking_events (device_id, livestock_id, event_start_at, event_end_at, "
                        + "temp_drop, min_temp, source, label, confidence, algorithm_version) "
                        + "VALUES (?, ?, ?, ?, 4.00, ?, ?, 'UNLABELED', 1.0, 'V1')",
                head.deviceId(), head.livestockId(), Timestamp.from(minus(t, 70)), Timestamp.from(minus(t, 69)),
                VALLEY_TEMP, source);

        // Activity: flat 1.00 over [T−56h, T−8.5h], surge 1.50 over [T−8h, T−0.5h].
        for (int k = 0; k <= 95; k++) {
            insertActivity(head, minus(t, 56 - 0.5 * k), new BigDecimal("1.00"), source);
        }
        for (int k = 0; k <= 15; k++) {
            insertActivity(head, minus(t, 8 - 0.5 * k), new BigDecimal("1.50"), source);
        }
    }

    /** All-quiet series: flat 39.00 over [T−78h, T−0.5h], flat 1.00 activity. */
    private void insertFlatSeries(Head head, String source) {
        Instant t = Instant.now();
        for (int k = 0; k <= 155; k++) { // 78h × 2/h − 1: T−78h .. T−0.5h
            insertTemp(head, minus(t, 78 - 0.5 * k), FLAT_TEMP, source);
        }
        for (int k = 0; k <= 111; k++) { // T−56h .. T−0.5h
            insertActivity(head, minus(t, 56 - 0.5 * k), new BigDecimal("1.00"), source);
        }
    }

    /** MANUAL BREEDING milestone {@code daysPregnant} days before now. */
    private void insertBreedingRecord(Head head, int daysPregnant) {
        jdbcTemplate.update(
                "INSERT INTO physiology_events (livestock_id, event_type, occurred_at, source) "
                        + "VALUES (?, 'BREEDING', ?, 'MANUAL')",
                head.livestockId(), Timestamp.from(Instant.now().minus(Duration.ofDays(daysPregnant))));
    }

    /** Preset ACTIVE CALVING_WARNING ticket (the raised-state fixture). */
    private void insertActiveCalvingTicket(Head head) {
        jdbcTemplate.update(
                "INSERT INTO alerts (farm_id, livestock_id, type, status, severity, source, message_key, message) "
                        + "VALUES (?, ?, 'CALVING_WARNING', 'ACTIVE', 'WARNING', 'RULE', "
                        + "'alert.health.calving', 'preset active calving ticket')",
                FARM_ID, head.livestockId());
    }

    private TemperatureLogJpaEntity insertTemp(Head head, Instant recordedAt, BigDecimal celsius, String source) {
        TemperatureLogJpaEntity entity = new TemperatureLogJpaEntity();
        entity.setLivestockId(head.livestockId());
        entity.setDeviceId(head.deviceId());
        entity.setTemperature(celsius);
        entity.setBaselineTemp(BASELINE_TEMP);
        entity.setRecordedAt(recordedAt);
        entity.setSource(source);
        return temperatureLogRepository.save(entity);
    }

    private void insertActivity(Head head, Instant recordedAt, BigDecimal activityIndex, String source) {
        ActivityLogJpaEntity entity = new ActivityLogJpaEntity();
        entity.setLivestockId(head.livestockId());
        entity.setDeviceId(head.deviceId());
        entity.setActivityIndex(activityIndex);
        entity.setRecordedAt(recordedAt);
        entity.setSource(source);
        activityLogRepository.save(entity);
    }

    /** THE production entry point — one full scheduler poll. */
    private void pollScheduler() {
        calvingScheduler.evaluateActiveLivestock();
    }

    // ── Query helpers ──────────────────────────────────────────────────

    private List<Map<String, Object>> calvingPredictions(long livestockId) {
        return jdbcTemplate.queryForList(
                "SELECT * FROM calving_predictions WHERE livestock_id = ? ORDER BY id", livestockId);
    }

    private List<Map<String, Object>> calvingTickets(long livestockId) {
        return jdbcTemplate.queryForList(
                "SELECT * FROM alerts WHERE livestock_id = ? AND type = 'CALVING_WARNING' ORDER BY id",
                livestockId);
    }

    private Integer snapshotCalvingScore(long livestockId) {
        return jdbcTemplate.queryForObject(
                "SELECT calving_risk_score FROM health_snapshots WHERE livestock_id = ?",
                Integer.class, livestockId);
    }

    private static int score(Map<String, Object> predictionRow) {
        return ((Number) predictionRow.get("risk_score")).intValue();
    }

    private static Instant instant(Object timestamp) {
        return ((Timestamp) timestamp).toInstant();
    }

    private static Instant minus(Instant base, double hoursAgo) {
        return base.minusMillis(Math.round(hoursAgo * 3_600_000));
    }

    private static String placeholders(int count) {
        return String.join(",", java.util.Collections.nCopies(count, "?"));
    }

    /** Restores the captured tenant-1 subscription row (null-safe on trial_ends_at). */
    private void restoreSubscription() {
        if (originalTier == null) {
            return;
        }
        if (originalTrialEndsAt == null) {
            jdbcTemplate.update("UPDATE subscriptions SET tier = ?, status = ?, trial_ends_at = NULL "
                    + "WHERE tenant_id = ?", originalTier, originalStatus, TENANT_ID);
        } else {
            jdbcTemplate.update("UPDATE subscriptions SET tier = ?, status = ?, trial_ends_at = ? "
                    + "WHERE tenant_id = ?", originalTier, originalStatus, originalTrialEndsAt, TENANT_ID);
        }
    }
}
