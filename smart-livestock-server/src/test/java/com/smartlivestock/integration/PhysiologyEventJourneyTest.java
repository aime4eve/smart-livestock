package com.smartlivestock.integration;

import com.smartlivestock.health.domain.model.EpidemicDispositionStatus;
import com.smartlivestock.health.domain.model.PhysiologyEventType;
import com.smartlivestock.health.domain.model.PhysiologySource;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyStageType;
import com.smartlivestock.health.domain.port.PhysiologyQueryPort.PhysiologyWindow;
import com.smartlivestock.health.infrastructure.persistence.entity.PhysiologyEventJpaEntity;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.PhysiologyEventJpaRepository;
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

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Map;
import java.util.TimeZone;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * NIX-256 Task 1a — physiology event journey: CRUD happy path, idempotent
 * POST, validation (future date / note length / bilingual messages),
 * ALERT_CONFIRM read-only rows, read-time window merge (manual pairing +
 * disposition lanes) and stage derivation.
 */
public class PhysiologyEventJourneyTest extends AbstractJourneyTest {

    private static final ZoneId ENTRY_ZONE = ZoneId.of("Asia/Shanghai");
    private static final String BASE = "/api/v1/farms/1/livestock/%s/physiology-events";

    @Autowired
    private PhysiologyEventJpaRepository physiologyEventRepository;

    @Autowired
    private EpidemicDispositionJpaRepository dispositionRepository;

    @Autowired
    private PhysiologyQueryPort physiologyQueryPort;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private Long firstLivestockId;
    private final List<Long> createdEventIds = new ArrayList<>();
    private final List<Long> createdDispositionIds = new ArrayList<>();

    @BeforeEach
    void setUpPhysiology() {
        // Dynamic livestock: take the first animal of farm 1.
        var data = getApi(ownerToken, "/api/v1/farms/1/livestock?page=1&pageSize=1");
        var items = getItems(data);
        assertThat(items).isNotEmpty();
        firstLivestockId = Long.valueOf(extractId(items.get(0)));
    }

    @AfterEach
    void tearDownPhysiology() {
        createdEventIds.forEach(id -> physiologyEventRepository.findById(id)
                .ifPresent(physiologyEventRepository::delete));
        createdEventIds.clear();
        createdDispositionIds.forEach(id -> dispositionRepository.findById(id)
                .ifPresent(dispositionRepository::delete));
        createdDispositionIds.clear();
    }

    private String base() {
        return String.format(BASE, firstLivestockId);
    }

    private PhysiologyEventJpaEntity insertManualEvent(Long livestockId, PhysiologyEventType type,
                                                       Instant occurredAt) {
        PhysiologyEventJpaEntity entity = new PhysiologyEventJpaEntity();
        entity.setLivestockId(livestockId);
        entity.setEventType(type);
        entity.setOccurredAt(occurredAt);
        entity.setSource(PhysiologySource.MANUAL);
        PhysiologyEventJpaEntity saved = physiologyEventRepository.save(entity);
        createdEventIds.add(saved.getId());
        return saved;
    }

    /**
     * Raw-SQL disposition insert (B2). The JPA entity's {@code @PrePersist}
     * stamps {@code createdAt}/{@code updatedAt} unconditionally, which
     * would overwrite the historic fixture times the window assertions
     * need — JdbcTemplate bypasses the callbacks and writes the columns
     * verbatim (column set = V20260926100000 DDL). Callers pass
     * second-truncated instants so the equality assertions survive
     * Postgres' microsecond timestamp rounding untouched.
     */
    private Long insertDisposition(Long livestockId, EpidemicDispositionStatus status,
                                   Instant createdAt, Instant completedAt, String cancelReason) {
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO epidemic_dispositions (farm_id, livestock_id, tier, action_code, status, "
                            + "reason_codes, created_at, updated_at, completed_at, cancel_reason_code) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    Statement.RETURN_GENERATED_KEYS);
            ps.setLong(1, 1L);
            ps.setLong(2, livestockId);
            ps.setString(3, "OBSERVATION");
            ps.setString(4, "HEALTH_RECHECK");
            ps.setString(5, status.name());
            ps.setArray(6, con.createArrayOf("text", new String[]{"DIRECT_SOURCE"}));
            bindUtcTimestamp(ps, 7, createdAt);
            bindUtcTimestamp(ps, 8, createdAt);
            bindUtcTimestamp(ps, 9, completedAt);
            ps.setString(10, cancelReason);
            return ps;
        }, keyHolder);
        Number key = keyHolder.getKey();
        assertThat(key).isNotNull();
        Long id = key.longValue();
        createdDispositionIds.add(id);
        return id;
    }

    /**
     * Bind an Instant into a TIMESTAMP (no tz) column the way Hibernate's
     * UTC mapping does, so the value read back through the JPA entity
     * equals the fixture instant exactly.
     */
    private static void bindUtcTimestamp(PreparedStatement ps, int index, Instant instant) throws SQLException {
        ps.setTimestamp(index, instant == null ? null : Timestamp.from(instant),
                Calendar.getInstance(TimeZone.getTimeZone("UTC")));
    }

    /** Farm-1 livestock that has no disposition rows yet (partial unique index). */
    private List<Long> farmLivestockWithoutDispositions(int count) {
        var data = getApi(ownerToken, "/api/v1/farms/1/livestock?page=1&pageSize=100");
        List<Long> ids = getItems(data).stream()
                .map(item -> Long.valueOf(extractId(item)))
                .filter(id -> dispositionRepository.findByLivestockId(id).isEmpty())
                .limit(count)
                .collect(Collectors.toList());
        assertThat(ids).hasSize(count);
        return ids;
    }

    // ── CRUD happy path ─────────────────────────────────────────

    @Test
    void crudHappyPath() {
        // CREATE — "2026-09-10" Asia/Shanghai midnight == 2026-09-09T16:00:00Z
        var created = postApi(ownerToken, base(),
                Map.of("eventType", "ILLNESS", "occurredAt", "2026-09-10", "note", "产后感冒"));
        String eventId = extractId(created);
        assertThat(eventId).isNotBlank();
        assertThat(created.get("eventType")).isEqualTo("ILLNESS");
        assertThat(created.get("source")).isEqualTo("MANUAL");
        assertThat(created.get("occurredAt")).isEqualTo("2026-09-09T16:00:00Z");
        createdEventIds.add(Long.valueOf(eventId));

        // READ — visible in the list for any authenticated farm member
        var workerList = getApi(workerToken, base());
        var workerItems = getItems(workerList);
        assertThat(workerItems).anySatisfy(item -> assertThat(item.get("id")).isEqualTo(Long.valueOf(eventId)));

        // UPDATE — "2026-09-12" → 2026-09-11T16:00:00Z
        var updated = putApi(ownerToken, base() + "/" + eventId,
                Map.of("occurredAt", "2026-09-12", "note", "复查正常"));
        assertThat(updated.get("occurredAt")).isEqualTo("2026-09-11T16:00:00Z");
        assertThat(updated.get("note")).isEqualTo("复查正常");
        assertThat(updated.get("updatedBy")).isNotNull();

        // DELETE
        deleteApi(ownerToken, base() + "/" + eventId);
        var after = getApi(ownerToken, base());
        assertThat(getItems(after))
                .noneSatisfy(item -> assertThat(item.get("id")).isEqualTo(Long.valueOf(eventId)));
    }

    // ── Idempotent POST ─────────────────────────────────────────

    @Test
    void postIsIdempotentOnSameTriple() {
        var first = postApi(ownerToken, base(),
                Map.of("eventType", "BREEDING", "occurredAt", "2026-08-20"));
        var second = postApi(ownerToken, base(),
                Map.of("eventType", "BREEDING", "occurredAt", "2026-08-20"));
        assertThat(extractId(second)).isEqualTo(extractId(first));
        createdEventIds.add(Long.valueOf(extractId(first)));

        Instant expected = LocalDate.parse("2026-08-20").atStartOfDay(ENTRY_ZONE).toInstant();
        long rows = physiologyEventRepository
                .findByLivestockIdAndEventTypeAndOccurredAtAndSource(
                        firstLivestockId, PhysiologyEventType.BREEDING, expected, PhysiologySource.MANUAL)
                .stream().count();
        assertThat(rows).isEqualTo(1);
    }

    // ── Validation ──────────────────────────────────────────────

    @Test
    void futureDateRejectedWithEnglishMessage() {
        String tomorrow = LocalDate.now(ENTRY_ZONE).plusDays(1).toString();
        HttpHeaders headers = authHeaders(ownerToken);
        headers.set("Accept-Language", "en");
        ResponseEntity<Map> resp = restTemplate.exchange(
                base(), HttpMethod.POST,
                new HttpEntity<>(Map.of("eventType", "ILLNESS", "occurredAt", tomorrow), headers), Map.class);
        assertError(resp, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        assertThat(String.valueOf(resp.getBody().get("message")))
                .isEqualTo("Date occurred cannot be in the future");
    }

    @Test
    void noteLongerThan500Rejected() {
        ResponseEntity<Map> resp = postRaw(ownerToken, base(),
                Map.of("eventType", "ILLNESS", "occurredAt", "2026-09-01", "note", "a".repeat(501)));
        assertError(resp, HttpStatus.BAD_REQUEST, "VALIDATION_ERROR");
        assertThat(String.valueOf(resp.getBody().get("message"))).contains("500");
    }

    @Test
    void livestockFromAnotherFarmRejected() {
        // A livestock id that does not exist (or belongs to another farm).
        ResponseEntity<Map> resp = postRaw(ownerToken, String.format(BASE, 999999L),
                Map.of("eventType", "ILLNESS", "occurredAt", "2026-09-01"));
        assertError(resp, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
        assertThat(String.valueOf(resp.getBody().get("message"))).isEqualTo("牲畜不存在或不属于当前牧场");
    }

    // ── ALERT_CONFIRM rows are read-only ────────────────────────

    @Test
    void alertConfirmRowsCannotBeEditedOrDeleted() {
        PhysiologyEventJpaEntity alertEvent = new PhysiologyEventJpaEntity();
        alertEvent.setLivestockId(firstLivestockId);
        alertEvent.setEventType(PhysiologyEventType.ILLNESS);
        alertEvent.setOccurredAt(Instant.parse("2026-09-05T00:00:00Z"));
        alertEvent.setSource(PhysiologySource.ALERT_CONFIRM);
        alertEvent = physiologyEventRepository.save(alertEvent);
        createdEventIds.add(alertEvent.getId());

        ResponseEntity<Map> putResp = putRaw(ownerToken, base() + "/" + alertEvent.getId(),
                Map.of("occurredAt", "2026-09-06"));
        assertError(putResp, HttpStatus.CONFLICT, "STATE_CONFLICT");

        ResponseEntity<Map> deleteResp = deleteRaw(ownerToken, base() + "/" + alertEvent.getId());
        assertError(deleteResp, HttpStatus.CONFLICT, "STATE_CONFLICT");
    }

    // ── Read-time window merge ──────────────────────────────────

    @Test
    void manualIllnessWithoutRecoveryStaysOpen() {
        Instant onset = Instant.now().minusSeconds(2 * 24 * 3600);
        insertManualEvent(firstLivestockId, PhysiologyEventType.ILLNESS, onset);

        List<PhysiologyWindow> windows = physiologyQueryPort.activeWindows(
                firstLivestockId, Instant.now().minusSeconds(7 * 24 * 3600), Instant.now().plusSeconds(24 * 3600));
        assertThat(windows).anySatisfy(w -> {
            assertThat(w.eventType()).isEqualTo(PhysiologyEventType.ILLNESS);
            assertThat(w.occurredAt()).isEqualTo(onset);
            assertThat(w.endedAt()).isNull();
            assertThat(w.sourceType()).isEqualTo("MANUAL");
            assertThat(w.refId()).isNull();
        });
    }

    @Test
    void manualIllnessWithRecoveryClosesAndFiltersByRange() {
        Instant onset = Instant.now().minusSeconds(10 * 24 * 3600);
        Instant recovered = Instant.now().minusSeconds(8 * 24 * 3600);
        insertManualEvent(firstLivestockId, PhysiologyEventType.ILLNESS, onset);
        insertManualEvent(firstLivestockId, PhysiologyEventType.RECOVERY, recovered);

        // Wide range: the closed window is present with both bounds.
        List<PhysiologyWindow> wide = physiologyQueryPort.activeWindows(
                firstLivestockId, Instant.now().minusSeconds(30 * 24 * 3600), Instant.now());
        assertThat(wide).anySatisfy(w -> {
            assertThat(w.occurredAt()).isEqualTo(onset);
            assertThat(w.endedAt()).isEqualTo(recovered);
            assertThat(w.sourceType()).isEqualTo("MANUAL");
        });

        // Range starting after recovery: the closed window no longer overlaps.
        List<PhysiologyWindow> narrow = physiologyQueryPort.activeWindows(
                firstLivestockId, Instant.now().minusSeconds(7 * 24 * 3600), Instant.now());
        assertThat(narrow)
                .extracting(PhysiologyWindow::occurredAt)
                .doesNotContain(onset);
    }

    @Test
    void dispositionWindowsMergeByStatus() {
        List<Long> ids = farmLivestockWithoutDispositions(3);
        Long pendingLivestock = ids.get(0);
        Long completedLivestock = ids.get(1);
        Long cancelledLivestock = ids.get(2);
        // Second precision: Postgres timestamps hold microseconds, so the
        // equality assertions below need values that round-trip exactly.
        Instant created = Instant.now().minusSeconds(3 * 24 * 3600).truncatedTo(ChronoUnit.SECONDS);
        Instant completedAt = Instant.now().minusSeconds(24 * 3600).truncatedTo(ChronoUnit.SECONDS);

        Long pendingId = insertDisposition(
                pendingLivestock, EpidemicDispositionStatus.PENDING, created, null, null);
        insertDisposition(completedLivestock, EpidemicDispositionStatus.COMPLETED, created, completedAt, null);
        insertDisposition(cancelledLivestock, EpidemicDispositionStatus.CANCELLED, created, null, "SOURCE_UNMARKED");

        Instant from = Instant.now().minusSeconds(30 * 24 * 3600);
        Instant to = Instant.now().plusSeconds(24 * 3600);

        // PENDING → open window [created_at, null) with disposition refId
        List<PhysiologyWindow> pendingWindows = physiologyQueryPort.activeWindows(pendingLivestock, from, to);
        assertThat(pendingWindows).anySatisfy(w -> {
            assertThat(w.eventType()).isEqualTo(PhysiologyEventType.ILLNESS);
            assertThat(w.sourceType()).isEqualTo("DISPOSITION");
            assertThat(w.refId()).isEqualTo(pendingId);
            assertThat(w.occurredAt()).isEqualTo(created);
            assertThat(w.endedAt()).isNull();
        });

        // COMPLETED → [created_at, completed_at]
        List<PhysiologyWindow> completedWindows = physiologyQueryPort.activeWindows(completedLivestock, from, to);
        assertThat(completedWindows).anySatisfy(w -> {
            assertThat(w.sourceType()).isEqualTo("DISPOSITION");
            assertThat(w.occurredAt()).isEqualTo(created);
            assertThat(w.endedAt()).isEqualTo(completedAt);
        });

        // CANCELLED (SOURCE_UNMARKED soft delete) → no window at all
        List<PhysiologyWindow> cancelledWindows = physiologyQueryPort.activeWindows(cancelledLivestock, from, to);
        assertThat(cancelledWindows).isEmpty();

        // Farm batch variant agrees with the per-livestock queries.
        var farmWindows = physiologyQueryPort.activeWindowsForFarm(1L, from, to);
        assertThat(farmWindows).containsKey(pendingLivestock);
        assertThat(farmWindows.get(pendingLivestock)).anySatisfy(
                w -> assertThat(w.refId()).isEqualTo(pendingId));
        assertThat(farmWindows).doesNotContainKey(cancelledLivestock);
    }

    // ── Timezone convention ─────────────────────────────────────

    @Test
    void entryDateIsShanghaiMidnightInUtc() {
        var created = postApi(ownerToken, base(),
                Map.of("eventType", "PREGNANCY_CHECK", "occurredAt", "2026-10-04"));
        createdEventIds.add(Long.valueOf(extractId(created)));

        PhysiologyEventJpaEntity stored = physiologyEventRepository
                .findById(Long.valueOf(extractId(created))).orElseThrow();
        // 2026-10-04T00:00+08:00 == 2026-10-03T16:00:00Z
        assertThat(stored.getOccurredAt()).isEqualTo(Instant.parse("2026-10-03T16:00:00Z"));
    }

    // ── Read-time merge in the list endpoint ────────────────────

    @Test
    void listMergesActiveDispositionRowAndProjectsStage() {
        Long livestockId = farmLivestockWithoutDispositions(1).get(0);
        Instant dispositionCreatedAt = Instant.now().minusSeconds(2 * 24 * 3600).truncatedTo(ChronoUnit.SECONDS);
        Long pendingId = insertDisposition(
                livestockId, EpidemicDispositionStatus.PENDING, dispositionCreatedAt, null, null);
        // Older manual illness still ongoing.
        insertManualEvent(livestockId, PhysiologyEventType.ILLNESS,
                Instant.now().minusSeconds(5 * 24 * 3600));

        var data = getApi(ownerToken, String.format(BASE, livestockId));
        var items = getItems(data);
        assertThat(items).isNotEmpty();

        // Merged DISPOSITION row is the newest (created_at after the manual
        // event) and carries the projection contract: id null, refId set,
        // active true.
        var first = items.get(0);
        assertThat(first.get("source")).isEqualTo("DISPOSITION");
        assertThat(first.get("eventType")).isEqualTo("ILLNESS");
        assertThat(first.get("id")).isNull();
        assertThat(((Number) first.get("refId")).longValue()).isEqualTo(pendingId);
        assertThat(first.get("active")).isEqualTo(true);

        // Manual unpaired illness row is flagged active too.
        assertThat(items).anySatisfy(item -> {
            assertThat(item.get("source")).isEqualTo("MANUAL");
            assertThat(item.get("eventType")).isEqualTo("ILLNESS");
            assertThat(item.get("active")).isEqualTo(true);
        });

        // No CALVING/DRY_OFF milestone for this animal → stage chip absent.
        assertThat(data.get("stage")).isNull();
    }

    // ── Stage derivation ────────────────────────────────────────

    @Test
    void currentStageFollowsSeededCalvingThenDryOff() {
        // Seeded demo cow SL-2024-012 calved 128 days ago (< 305) → LACTATING.
        Long livestockId = findLivestockIdByCode("SL-2024-012");
        var lactating = physiologyQueryPort.currentStage(livestockId);
        assertThat(lactating).isPresent();
        assertThat(lactating.get().type()).isEqualTo(PhysiologyStageType.LACTATING);
        assertThat(lactating.get().since()).isAfter(Instant.now().minusSeconds(130 * 24 * 3600));
        assertThat(lactating.get().since()).isBefore(Instant.now().minusSeconds(126 * 24 * 3600));

        // The list endpoint projects the same stage chip.
        var listData = getApi(ownerToken, String.format(BASE, livestockId));
        @SuppressWarnings("unchecked")
        Map<String, Object> stageChip = (Map<String, Object>) listData.get("stage");
        assertThat(stageChip).isNotNull();
        assertThat(stageChip.get("type")).isEqualTo("LACTATING");
        assertThat(Instant.parse(String.valueOf(stageChip.get("since"))))
                .isEqualTo(lactating.get().since());

        // A newer manual DRY_OFF flips the stage to DRY — port and endpoint agree.
        Instant dryOffAt = Instant.now().minusSeconds(24 * 3600);
        insertManualEvent(livestockId, PhysiologyEventType.DRY_OFF, dryOffAt);
        var dry = physiologyQueryPort.currentStage(livestockId);
        assertThat(dry).isPresent();
        assertThat(dry.get().type()).isEqualTo(PhysiologyStageType.DRY);
        assertThat(dry.get().since()).isEqualTo(dryOffAt);

        var dryList = getApi(ownerToken, String.format(BASE, livestockId));
        @SuppressWarnings("unchecked")
        Map<String, Object> dryChip = (Map<String, Object>) dryList.get("stage");
        assertThat(dryChip.get("type")).isEqualTo("DRY");
        assertThat(Instant.parse(String.valueOf(dryChip.get("since")))).isEqualTo(dryOffAt);
    }

    private Long findLivestockIdByCode(String code) {
        var data = getApi(ownerToken, "/api/v1/farms/1/livestock?page=1&pageSize=100");
        return getItems(data).stream()
                .filter(item -> code.equals(item.get("livestockCode")))
                .map(item -> Long.valueOf(extractId(item)))
                .findFirst()
                .orElseThrow();
    }
}
