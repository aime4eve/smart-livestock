package com.smartlivestock.integration;

import com.smartlivestock.health.application.service.DrinkingEventDetectionService;
import com.smartlivestock.health.domain.model.DrinkingAlgorithmVersion;
import com.smartlivestock.health.domain.model.DrinkingEventLabel;
import com.smartlivestock.health.domain.model.DrinkingEventSources;
import com.smartlivestock.health.domain.port.DeviceQueryPort;
import com.smartlivestock.health.domain.port.DeviceQueryPort.CapsuleBinding;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.infrastructure.persistence.entity.DrinkingEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.entity.TemperatureLogJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.DrinkingEventJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.TemperatureLogJpaRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;

import java.math.BigDecimal;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TimeZone;
import java.util.TreeMap;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NIX-256 Task 3 — drinking event journey (Testcontainers; not runnable on
 * machines without Docker — compile-only here, executed in CI/dev).
 * Covers: DATAGEN points producing source-tagged events through
 * {@code recalculateDevice}, PATCH label flips with bilingual validation,
 * POST /manual (happy path / idempotent repeat / future rejection /
 * no-device rejection), the F6+§15.4 recalc semantics (MANUAL rows never
 * deleted, CONFIRMED/REJECTED labels restored onto re-derived rows,
 * labeled rows that are no longer detected come back), the candidate row
 * data feeding the counting contract (the isCounted predicate itself is
 * unit-tested in {@code DrinkingEventServiceTest} — it is package-visible),
 * and the fever exclusion windows end to end (ACTIVE TEMPERATURE_ABNORMAL
 * alert + the 6h defervescence buffer over a resolved one, M8).
 */
public class DrinkingEventJourneyTest extends AbstractJourneyTest {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");
    private static final String BASE = "/api/v1/farms/1/livestock/%s/drinking-events";
    private static final List<String> FEVER_ALERT_TYPES = List.of("TEMPERATURE_ABNORMAL");

    @Autowired
    private DrinkingEventDetectionService detectionService;

    @Autowired
    private DrinkingEventJpaRepository eventRepository;

    @Autowired
    private TemperatureLogJpaRepository temperatureLogRepository;

    @Autowired
    private DeviceQueryPort deviceQueryPort;

    @Autowired
    private RanchQueryPort ranchQueryPort;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Long boundLivestockId;
    private Long capsuleDeviceId;
    private Long unboundLivestockId;

    /** Previous Shanghai day — one clean cow-day for deterministic μ/σ. */
    private LocalDate fixtureDay;

    private final List<Long> createdEventIds = new ArrayList<>();
    private final List<TemperatureLogJpaEntity> createdTemperatureLogs = new ArrayList<>();
    private final List<Long> createdAlertIds = new ArrayList<>();

    @BeforeEach
    void setUpDrinking() {
        fixtureDay = LocalDate.now(ZONE).minusDays(1);
        List<Long> farmLivestockIds = ranchQueryPort.findAllByFarmId(1L).stream()
                .map(LivestockInfo::id)
                .collect(Collectors.toList());
        // Fever alerts of the farm own open-ended exclusion windows — pick a
        // capsule-bound animal whose fixture day is free of them so the
        // detection assertions stay deterministic.
        Map<Long, List<Instant[]>> alertSpansByLivestock = feverAlertSpansByLivestock(farmLivestockIds);
        List<CapsuleBinding> bindings = deviceQueryPort.findActiveCapsuleBindings(farmLivestockIds);
        Instant fixtureStart = fixtureDay.atStartOfDay(ZONE).toInstant();
        Instant fixtureEnd = fixtureStart.plus(Duration.ofDays(1));
        CapsuleBinding chosen = bindings.stream()
                .filter(b -> alertSpansByLivestock.getOrDefault(b.livestockId(), List.of()).stream()
                        .noneMatch(span -> overlaps(span, fixtureStart, fixtureEnd)))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException(
                        "Seed data has no fever-free farm-1 livestock with an active capsule"));
        boundLivestockId = chosen.livestockId();
        capsuleDeviceId = chosen.deviceId();
        unboundLivestockId = farmLivestockIds.stream()
                .filter(id -> bindings.stream().noneMatch(b -> b.livestockId().equals(id)))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Seed data has no livestock without a capsule"));
    }

    @AfterEach
    void tearDownDrinking() {
        Instant dayStart = fixtureDay.atStartOfDay(ZONE).toInstant();
        // Sweep by device over the whole fixture day window — recalcs insert
        // rows whose ids were never tracked (restored rows get fresh ids).
        eventRepository.findByDeviceIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThan(
                        capsuleDeviceId, dayStart.minus(Duration.ofHours(2)), dayStart.plus(Duration.ofHours(26)))
                .forEach(eventRepository::delete);
        createdEventIds.forEach(id -> eventRepository.findById(id).ifPresent(eventRepository::delete));
        createdEventIds.clear();
        temperatureLogRepository.deleteAll(createdTemperatureLogs);
        createdTemperatureLogs.clear();
        createdAlertIds.forEach(id -> jdbcTemplate.update("DELETE FROM alerts WHERE id = ?", id));
        createdAlertIds.clear();
    }

    private String base(Long livestockId) {
        return String.format(BASE, livestockId);
    }

    private Instant wall(String wallClock) {
        return LocalDateTime.parse(wallClock).atZone(ZONE).toInstant();
    }

    private String fixtureWall(String timeOfDay) {
        return fixtureDay.atTime(LocalDateTime.parse("2000-01-01T" + timeOfDay).toLocalTime()).toString();
    }

    // ── Fixture helpers ─────────────────────────────────────────

    private Map<Long, List<Instant[]>> feverAlertSpansByLivestock(List<Long> farmLivestockIds) {
        Instant since = Instant.now().minus(Duration.ofDays(3));
        Map<Long, List<Instant[]>> spans = new LinkedHashMap<>();
        ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, FEVER_ALERT_TYPES)
                .forEach(alert -> spans.computeIfAbsent(alert.livestockId(), ignored -> new ArrayList<>())
                        .add(new Instant[]{alert.createdAt(), null}));
        ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(1L, FEVER_ALERT_TYPES, since)
                .forEach(alert -> spans.computeIfAbsent(alert.livestockId(), ignored -> new ArrayList<>())
                        .add(new Instant[]{alert.createdAt(), alert.resolvedAt()}));
        return spans;
    }

    private static boolean overlaps(Instant[] span, Instant from, Instant to) {
        return span[0].isBefore(to) && (span[1] == null || span[1].isAfter(from));
    }

    /**
     * Insert one 5-min flat series with per-timestamp temperature overrides
     * (the valleys), all under one source. Returns the saved points in
     * chronological order; points whose wall clock appears in
     * {@code sinkTimes} are also collected into {@code sink} for later
     * deletion (valley removal scenarios).
     */
    private List<TemperatureLogJpaEntity> insertSeries(String fromTime, String toTime, double flatTemp,
                                                       Map<String, Double> overrides, String source,
                                                       Set<String> sinkTimes, List<TemperatureLogJpaEntity> sink) {
        Map<LocalDateTime, Double> byTime = new TreeMap<>();
        LocalDateTime cursor = LocalDateTime.parse(fixtureWall(fromTime));
        LocalDateTime end = LocalDateTime.parse(fixtureWall(toTime));
        while (!cursor.isAfter(end)) {
            byTime.put(cursor, flatTemp);
            cursor = cursor.plusMinutes(5);
        }
        overrides.forEach((time, temp) -> byTime.put(LocalDateTime.parse(fixtureWall(time)), temp));
        Set<LocalDateTime> sinkLocalTimes = sinkTimes == null ? Set.of() : sinkTimes.stream()
                .map(t -> LocalDateTime.parse(fixtureWall(t)))
                .collect(Collectors.toSet());
        List<TemperatureLogJpaEntity> saved = new ArrayList<>();
        byTime.forEach((time, temp) -> {
            TemperatureLogJpaEntity entity = new TemperatureLogJpaEntity();
            entity.setLivestockId(boundLivestockId);
            entity.setDeviceId(capsuleDeviceId);
            entity.setTemperature(BigDecimal.valueOf(temp).setScale(2, java.math.RoundingMode.HALF_UP));
            entity.setBaselineTemp(new BigDecimal("38.50"));
            entity.setRecordedAt(time.atZone(ZONE).toInstant());
            entity.setSource(source);
            saved.add(temperatureLogRepository.save(entity));
        });
        createdTemperatureLogs.addAll(saved);
        if (sink != null) {
            sink.addAll(saved.stream()
                    .filter(e -> sinkLocalTimes.contains(LocalDateTime.ofInstant(e.getRecordedAt(), ZONE)))
                    .toList());
        }
        return saved;
    }

    private void recalcFixtureDay() {
        Instant dayStart = fixtureDay.atStartOfDay(ZONE).toInstant();
        detectionService.recalculateDevice(capsuleDeviceId, dayStart, dayStart.plus(Duration.ofDays(1)));
    }

    /**
     * Raw-SQL TEMPERATURE_ABNORMAL alert insert (M8): the alert is fixture
     * data owned by this test and stamped at exact fixture-day times — the
     * JPA entity's {@code @PrePersist} would overwrite {@code created_at}
     * with now(). {@code created_at} binds with a UTC calendar (matching
     * Hibernate's Instant mapping into the tz-less column);
     * {@code resolved_at} is timestamptz and binds as an absolute instant.
     */
    private void insertFeverAlert(String status, Instant createdAt, Instant resolvedAt) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO alerts (farm_id, livestock_id, type, status, severity, message, "
                            + "resolved_type, resolved_at, created_at, updated_at) "
                            + "VALUES (?, ?, 'TEMPERATURE_ABNORMAL', ?, 'WARNING', ?, ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, 1L);
            ps.setLong(2, boundLivestockId);
            ps.setString(3, status);
            ps.setString(4, "journey fixture fever alert");
            ps.setString(5, resolvedAt == null ? null : "AUTO");
            if (resolvedAt == null) {
                ps.setNull(6, Types.TIMESTAMP_WITH_TIMEZONE);
            } else {
                ps.setObject(6, OffsetDateTime.ofInstant(resolvedAt, ZoneOffset.UTC));
            }
            bindUtcTimestamp(ps, 7, createdAt);
            bindUtcTimestamp(ps, 8, createdAt);
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        assertThat(key).isNotNull();
        createdAlertIds.add(key.longValue());
    }

    private static void bindUtcTimestamp(PreparedStatement ps, int index, Instant instant) throws SQLException {
        ps.setTimestamp(index, Timestamp.from(instant),
                Calendar.getInstance(TimeZone.getTimeZone("UTC")));
    }

    private List<DrinkingEventJpaEntity> fixtureDayRows() {
        Instant dayStart = fixtureDay.atStartOfDay(ZONE).toInstant();
        return eventRepository.findByDeviceIdAndEventStartAtGreaterThanEqualAndEventStartAtLessThan(
                capsuleDeviceId, dayStart, dayStart.plus(Duration.ofDays(1)));
    }

    private Long insertEventRow(Instant startAt, Instant endAt, String source, DrinkingEventLabel label,
                                String algorithmVersion) {
        DrinkingEventJpaEntity entity = new DrinkingEventJpaEntity();
        entity.setDeviceId(capsuleDeviceId);
        entity.setLivestockId(boundLivestockId);
        entity.setEventStartAt(startAt);
        entity.setEventEndAt(endAt);
        entity.setTempDrop(new BigDecimal("2.20"));
        entity.setMinTemp(new BigDecimal("36.80"));
        entity.setSource(source);
        entity.setLabel(label);
        entity.setConfidence(new BigDecimal("0.850"));
        entity.setAlgorithmVersion(algorithmVersion);
        DrinkingEventJpaEntity saved = eventRepository.save(entity);
        createdEventIds.add(saved.getId());
        return saved.getId();
    }

    private ResponseEntity<Map> patchLabel(Long livestockId, Long eventId, String label, String acceptLanguage) {
        HttpHeaders headers = authHeaders(ownerToken);
        if (acceptLanguage != null) {
            headers.set("Accept-Language", acceptLanguage);
        }
        return restTemplate.exchange(base(livestockId) + "/" + eventId + "/label", HttpMethod.PATCH,
                new HttpEntity<>(Map.of("label", label), headers), Map.class);
    }

    private ResponseEntity<Map> postManual(Long livestockId, String eventStartAt, String note) {
        Map<String, Object> body = new HashMap<>();
        body.put("eventStartAt", eventStartAt);
        if (note != null) {
            body.put("note", note);
        }
        return postRaw(ownerToken, base(livestockId) + "/manual", body);
    }

    /** Extract the created row id from a postRaw response envelope. */
    @SuppressWarnings("unchecked")
    private Long createdId(ResponseEntity<Map> response) {
        Map<String, Object> body = response.getBody();
        assertThat(body).isNotNull();
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        assertThat(data).isNotNull();
        return Long.valueOf(extractId(data));
    }

    // ── 1. DATAGEN points → source-tagged events ────────────────

    @Test
    void datagenPointsProduceSourceTaggedEvents() {
        insertSeries("T08:00", "T12:00", 39.0, Map.of(
                "T09:30", 39.0, "T09:35", 37.5, "T09:40", 36.8,
                "T09:45", 37.3, "T09:50", 38.2, "T10:00", 39.0), "DATAGEN", null, null);
        recalcFixtureDay();

        List<DrinkingEventJpaEntity> rows = fixtureDayRows();
        assertThat(rows).hasSize(1);
        DrinkingEventJpaEntity row = rows.get(0);
        assertThat(row.getSource()).isEqualTo("DATAGEN");           // source passthrough (§4)
        assertThat(row.getLivestockId()).isEqualTo(boundLivestockId);
        assertThat(row.getAlgorithmVersion()).isEqualTo(DrinkingAlgorithmVersion.V1);
        assertThat(row.getLabel()).isEqualTo(DrinkingEventLabel.UNLABELED);
        assertThat(row.getEventStartAt()).isEqualTo(wall(fixtureWall("T09:30")));
        assertThat(row.getEventEndAt()).isEqualTo(wall(fixtureWall("T09:40")));
        assertThat(row.getTempDrop()).isEqualByComparingTo(new BigDecimal("2.20"));
        assertThat(row.getConfidence()).isBetween(new BigDecimal("0.000"), new BigDecimal("1.000"));
    }

    // ── 2. PATCH label: flips, resets, validation ────────────────

    @Test
    void patchLabelFlipsResetsAndValidates() {
        Long eventId = insertEventRow(wall(fixtureWall("T09:30")), wall(fixtureWall("T09:40")),
                "DATAGEN", DrinkingEventLabel.UNLABELED, DrinkingAlgorithmVersion.V1);

        // Confirm
        ResponseEntity<Map> confirmed = patchLabel(boundLivestockId, eventId, "CONFIRMED", null);
        assertOk(confirmed);
        assertThat(eventRepository.findById(eventId).orElseThrow().getLabel())
                .isEqualTo(DrinkingEventLabel.CONFIRMED);

        // Reset
        ResponseEntity<Map> reset = patchLabel(boundLivestockId, eventId, "UNLABELED", null);
        assertOk(reset);
        assertThat(eventRepository.findById(eventId).orElseThrow().getLabel())
                .isEqualTo(DrinkingEventLabel.UNLABELED);

        // Invalid label → 400 with localized message
        HttpHeaders headers = authHeaders(ownerToken);
        headers.set("Accept-Language", "en");
        ResponseEntity<Map> invalid = restTemplate.exchange(
                base(boundLivestockId) + "/" + eventId + "/label", HttpMethod.PATCH,
                new HttpEntity<>(Map.of("label", "MAYBE"), headers), Map.class);
        assertError(invalid, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        assertThat(String.valueOf(invalid.getBody().get("message"))).isEqualTo("Invalid label value");

        // Event of another livestock → 404
        ResponseEntity<Map> wrongLivestock = patchLabel(unboundLivestockId, eventId, "CONFIRMED", null);
        assertError(wrongLivestock, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }

    // ── 3. POST /manual: happy path + future + no device ─────────

    @Test
    void manualPostCreatesConfirmedRowAndRejectsFutureAndNoDevice() {
        // Happy path — "yyyy-MM-dd HH:mm" Asia/Shanghai wall clock → UTC.
        ResponseEntity<Map> created = postManual(boundLivestockId, fixtureWall("T09:00"), "morning drink missed");
        assertOk(created);
        Long id = createdId(created);
        createdEventIds.add(id);
        // MANUAL rows are human-asserted: confidence 1.0 never flags low.
        assertThat(created.getBody().get("data")).isNotNull();
        @SuppressWarnings("unchecked")
        Map<String, Object> createdData = (Map<String, Object>) created.getBody().get("data");
        assertThat(createdData.get("lowConfidence")).isEqualTo(false);

        DrinkingEventJpaEntity row = eventRepository.findById(id).orElseThrow();
        assertThat(row.getSource()).isEqualTo(DrinkingEventSources.MANUAL);
        assertThat(row.getLabel()).isEqualTo(DrinkingEventLabel.CONFIRMED);
        assertThat(row.getConfidence()).isEqualByComparingTo(BigDecimal.ONE);
        assertThat(row.getAlgorithmVersion()).isEqualTo(DrinkingAlgorithmVersion.MANUAL);
        assertThat(row.getEventStartAt()).isEqualTo(wall(fixtureWall("T09:00")));
        assertThat(row.getEventEndAt()).isEqualTo(wall(fixtureWall("T09:00"))); // end = start
        assertThat(row.getTempDrop()).isNull();                               // no temperature observation
        assertThat(row.getMinTemp()).isNull();
        assertThat(row.getNote()).isEqualTo("morning drink missed");

        // Same (device, start, manual) POST again → the existing row, not a
        // duplicate and not a 500 (m-d idempotency, physiology convention).
        ResponseEntity<Map> repeat = postManual(boundLivestockId, fixtureWall("T09:00"), null);
        assertOk(repeat);
        assertThat(createdId(repeat)).isEqualTo(id);
        assertThat(eventRepository.findByDeviceIdAndEventStartAtAndAlgorithmVersion(
                capsuleDeviceId, wall(fixtureWall("T09:00")), DrinkingAlgorithmVersion.MANUAL)).isPresent();

        // Future time → 400 error.drinking.futureDate (zh default)
        String future = LocalDate.now(ZONE).plusDays(1) + " 09:00";
        ResponseEntity<Map> futureResp = postManual(boundLivestockId, future, null);
        assertError(futureResp, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        assertThat(String.valueOf(futureResp.getBody().get("message"))).isEqualTo("饮水时刻不能晚于现在");

        // Livestock without capsule → 400 error.drinking.noDevice
        ResponseEntity<Map> noDevice = postManual(unboundLivestockId, fixtureWall("T09:00"), null);
        assertError(noDevice, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        assertThat(String.valueOf(noDevice.getBody().get("message"))).isEqualTo("该牲畜未绑定瘤胃胶囊");
    }

    // ── 4. Recalc semantics: F6 delete + §15.4 label preservation ─

    @Test
    void recalcPreservesManualRowsLabelsAndRestoresLabeledRows() {
        // Two valleys 40 min apart → two events on the first pass. One shared
        // series — the same timestamp must never be inserted twice (μ/σ).
        List<TemperatureLogJpaEntity> valleyTwoPoints = new ArrayList<>();
        insertSeries("T13:00", "T17:00", 39.0, Map.of(
                "T14:30", 39.0, "T14:35", 37.0, "T14:45", 38.2, "T14:55", 39.0,
                "T15:10", 39.0, "T15:15", 37.0, "T15:20", 38.5, "T15:25", 39.0), "DATAGEN",
                Set.of("T15:10", "T15:15", "T15:20", "T15:25"), valleyTwoPoints);
        assertThat(valleyTwoPoints).hasSize(4);
        recalcFixtureDay();

        List<DrinkingEventJpaEntity> first = fixtureDayRows();
        assertThat(first).hasSize(2);
        DrinkingEventJpaEntity valleyOne = first.stream()
                .filter(r -> r.getEventStartAt().equals(wall(fixtureWall("T14:30")))).findFirst().orElseThrow();
        DrinkingEventJpaEntity valleyTwo = first.stream()
                .filter(r -> r.getEventStartAt().equals(wall(fixtureWall("T15:10")))).findFirst().orElseThrow();

        // Human verdicts + one manual back-fill inside the same window.
        valleyOne.setLabel(DrinkingEventLabel.CONFIRMED);
        valleyTwo.setLabel(DrinkingEventLabel.REJECTED);
        eventRepository.saveAll(List.of(valleyOne, valleyTwo));
        ResponseEntity<Map> manual = postManual(boundLivestockId, fixtureWall("T16:00"), null);
        assertOk(manual);
        createdEventIds.add(createdId(manual));

        // Re-run the same window: labels are restored onto re-derived rows,
        // the MANUAL row survives, no duplicates appear.
        recalcFixtureDay();
        List<DrinkingEventJpaEntity> second = fixtureDayRows();
        assertThat(second).hasSize(3); // 2 algorithm + 1 manual
        assertThat(second.stream().filter(r -> DrinkingEventSources.MANUAL.equals(r.getSource()))).hasSize(1);
        assertThat(second.stream()
                .filter(r -> r.getEventStartAt().equals(wall(fixtureWall("T14:30")))
                        && r.getLabel() == DrinkingEventLabel.CONFIRMED))
                .hasSize(1);
        assertThat(second.stream()
                .filter(r -> r.getEventStartAt().equals(wall(fixtureWall("T15:10")))
                        && r.getLabel() == DrinkingEventLabel.REJECTED))
                .hasSize(1);

        // The second valley's points disappear (back-fill removed again):
        // the REJECTED verdict must survive the recalc even though the
        // detector no longer finds the valley (§15.4 restore path).
        temperatureLogRepository.deleteAll(valleyTwoPoints);
        recalcFixtureDay();
        List<DrinkingEventJpaEntity> third = fixtureDayRows();
        assertThat(third).hasSize(3);
        assertThat(third.stream()
                .filter(r -> r.getEventStartAt().equals(wall(fixtureWall("T14:30")))
                        && r.getLabel() == DrinkingEventLabel.CONFIRMED))
                .hasSize(1);
        assertThat(third.stream()
                .filter(r -> r.getEventStartAt().equals(wall(fixtureWall("T15:10")))
                        && r.getLabel() == DrinkingEventLabel.REJECTED
                        && !DrinkingEventSources.MANUAL.equals(r.getSource())))
                .hasSize(1);
        assertThat(third.stream().filter(r -> DrinkingEventSources.MANUAL.equals(r.getSource()))).hasSize(1);
    }

    // ── 5. Candidate rows: data feeding the counting contract ────

    @Test
    void candidateRowsFollowCountingDataContract() {
        // The isCounted predicate itself (label != REJECTED &&
        // (source != ALGORITHM_CANDIDATE || label == CONFIRMED), revised
        // spec §15.3) is package-visible and unit-tested in
        // DrinkingEventServiceTest; here we pin the persisted row shape it
        // reads: candidates carry source/label/confidence < 1 and stay
        // untouched by a label flip on the source column.
        Long candidateId = insertEventRow(wall(fixtureWall("T09:30")), wall(fixtureWall("T09:35")),
                DrinkingEventSources.ALGORITHM_CANDIDATE, DrinkingEventLabel.UNLABELED,
                DrinkingAlgorithmVersion.V1);
        DrinkingEventJpaEntity candidate = eventRepository.findById(candidateId).orElseThrow();
        assertThat(candidate.getConfidence()).isLessThan(BigDecimal.ONE); // borderline by construction

        // Confirming a candidate flips only the label — the source stays
        // ALGORITHM_CANDIDATE so the statistics contract (label/source pair)
        // keeps audit information about the row's origin.
        ResponseEntity<Map> confirmed = patchLabel(boundLivestockId, candidateId, "CONFIRMED", null);
        assertOk(confirmed);
        DrinkingEventJpaEntity promoted = eventRepository.findById(candidateId).orElseThrow();
        assertThat(promoted.getLabel()).isEqualTo(DrinkingEventLabel.CONFIRMED);
        assertThat(promoted.getSource()).isEqualTo(DrinkingEventSources.ALGORITHM_CANDIDATE);
    }

    // ── 6. Fever exclusion windows end to end (spec §4, M8) ──────

    @Test
    void feverAlertActiveExcludesDetection() {
        // The same detectable valley shape as test 1, but an ACTIVE
        // TEMPERATURE_ABNORMAL alert created mid-day opens an exclusion
        // window [created_at, ∞) — the buffered window swallows the valley
        // and the whole recalculation must yield zero rows for the day.
        insertSeries("T08:00", "T12:00", 39.0, Map.of(
                "T09:30", 39.0, "T09:35", 37.5, "T09:40", 36.8,
                "T09:45", 37.3, "T09:50", 38.2, "T10:00", 39.0), "DATAGEN", null, null);
        insertFeverAlert("ACTIVE", wall(fixtureWall("T09:00")), null);
        recalcFixtureDay();

        assertThat(fixtureDayRows()).isEmpty();
    }

    @Test
    void defervescenceBufferExtendsExclusion() {
        // AUTO_RESOLVED alert closes at 12:00 inside the fixture day: the
        // raw alert window ends there, but the 6h defervescence buffer
        // keeps exclusion open until 18:00. The 14:00 valley starts 2h
        // after resolution — inside the buffered window, dropped; the
        // 20:00 valley is outside it and survives, proving the exclusion
        // is window-bounded rather than whole-day.
        insertFeverAlert("AUTO_RESOLVED", wall(fixtureWall("T06:00")), wall(fixtureWall("T12:00")));
        insertSeries("T08:00", "T22:00", 39.0, Map.ofEntries(
                Map.entry("T14:00", 39.0), Map.entry("T14:05", 37.5), Map.entry("T14:10", 36.8),
                Map.entry("T14:15", 37.3), Map.entry("T14:20", 38.2), Map.entry("T14:30", 39.0),
                Map.entry("T20:00", 39.0), Map.entry("T20:05", 37.5), Map.entry("T20:10", 36.8),
                Map.entry("T20:15", 37.3), Map.entry("T20:20", 38.2), Map.entry("T20:30", 39.0)),
                "DATAGEN", null, null);
        recalcFixtureDay();

        List<DrinkingEventJpaEntity> rows = fixtureDayRows();
        assertThat(rows).extracting(DrinkingEventJpaEntity::getEventStartAt)
                .containsExactly(wall(fixtureWall("T20:00")));
    }
}
