package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ContactTrace;
import com.smartlivestock.health.domain.port.GpsTrajectoryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.ContactTraceRepository;
import com.smartlivestock.health.infrastructure.acl.GpsTrajectoryPortImpl;
import com.smartlivestock.iot.domain.repository.GpsLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Real-database integration tests (Testcontainers, lesson #19) for the
 * contact analysis kernel shared by the scheduler track and the
 * mark-diseased snapshot track. Trajectories are written straight into
 * gps_logs through device/installation bindings so the whole livestock ->
 * device -> gps_logs read path is exercised.
 */
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class ContactAnalysisServiceIntegrationTest {

    private static final long FARM_ID = 1L;
    private static final double BASE_LAT = 28.0d;
    private static final double BASE_LNG = 113.0d;
    /** Meters per degree of latitude for a pure-latitude offset under the
     *  haversine constant used by TrackLineCalculator (R = 6,371 km). */
    private static final double METERS_PER_DEG_LAT = Math.PI / 180.0d * 6_371_000.0d;

    /** Defaults under test: proximity 30m, minimum duration 5min, 60s buckets. */
    private static final double PROXIMITY_THRESHOLD = 30.0d;
    private static final int MIN_DURATION_MINUTES = 5;
    private static final long ALIGN_SECONDS = 60L;

    @Autowired
    private ContactTraceRepository contactTraceRepository;
    @Autowired
    private InstallationRepository installationRepository;
    @Autowired
    private GpsLogRepository gpsLogRepository;
    @PersistenceContext
    private EntityManager entityManager;

    /** Unique suffixes so repeated runs never collide with seed device/livestock codes. */
    private static final AtomicLong CODE_SEQ = new AtomicLong(System.currentTimeMillis() % 1_000_000);

    private Instant base;
    private ContactAnalysisService service;

    @BeforeEach
    void setUp() {
        // 30 minutes back: the analysis window [cutoff, now] covers the whole fixture.
        base = Instant.now().minus(Duration.ofMinutes(30));
    }

    // ── Fixtures ─────────────────────────────────────────────────────

    private record Cow(long livestockId, long deviceId) {}

    private Cow insertCow(String tag) {
        long seq = CODE_SEQ.incrementAndGet();
        String livestockCode = "CT-LIVE-" + tag + "-" + seq;
        String deviceCode = "CT-DEV-" + tag + "-" + seq;

        entityManager.createNativeQuery("""
                INSERT INTO livestock (farm_id, livestock_code, breed, gender)
                VALUES (?, ?, '测试牛', 'FEMALE')
                """).setParameter(1, FARM_ID).setParameter(2, livestockCode).executeUpdate();
        entityManager.createNativeQuery("""
                INSERT INTO devices (tenant_id, device_code, device_type, status)
                VALUES (1, ?, 'TRACKER', 'ACTIVE')
                """).setParameter(1, deviceCode).executeUpdate();

        long livestockId = idByCode("livestock", "livestock_code", livestockCode);
        long deviceId = idByCode("devices", "device_code", deviceCode);
        entityManager.createNativeQuery("""
                INSERT INTO installations (device_id, livestock_id, installed_at)
                VALUES (?, ?, NOW())
                """).setParameter(1, deviceId).setParameter(2, livestockId).executeUpdate();
        return new Cow(livestockId, deviceId);
    }

    private long idByCode(String table, String codeColumn, String code) {
        return ((Number) entityManager.createNativeQuery(
                        "SELECT id FROM " + table + " WHERE " + codeColumn + " = ?")
                .setParameter(1, code)
                .getSingleResult()).longValue();
    }

    private void insertGps(long deviceId, double lat, double lng, Instant at) {
        entityManager.createNativeQuery("""
                INSERT INTO gps_logs (device_id, latitude, longitude, recorded_at, source)
                VALUES (?, ?, ?, ?, 'AGENTIC_PLATFORM')
                """)
                .setParameter(1, deviceId)
                .setParameter(2, BigDecimal.valueOf(lat).setScale(7, RoundingMode.HALF_UP))
                .setParameter(3, BigDecimal.valueOf(lng).setScale(7, RoundingMode.HALF_UP))
                .setParameter(4, Timestamp.from(at))
                .executeUpdate();
    }

    /** One fix per minute, at a constant latitude offset (meters) from the base point. */
    private void track(Cow cow, double offsetMeters, int minutes) {
        for (int k = 0; k < minutes; k++) {
            insertGps(cow.deviceId(), BASE_LAT + offsetMeters / METERS_PER_DEG_LAT, BASE_LNG,
                    base.plusSeconds(60L * k));
        }
    }

    private void buildService(Cow... cows) {
        List<LivestockInfo> livestockInfos = Arrays.stream(cows)
                .map(cow -> new LivestockInfo(cow.livestockId(), FARM_ID,
                        "CT-" + cow.livestockId(), "FEMALE", "测试"))
                .toList();
        GpsTrajectoryPort gpsPort = new GpsTrajectoryPortImpl(installationRepository, gpsLogRepository);
        RanchQueryPort ranchPort = mock(RanchQueryPort.class);
        when(ranchPort.findAllByFarmId(anyLong())).thenReturn(livestockInfos);
        service = new ContactAnalysisService(
                contactTraceRepository, gpsPort, ranchPort,
                PROXIMITY_THRESHOLD, MIN_DURATION_MINUTES, ALIGN_SECONDS);
    }

    private List<ContactTrace> rowsFor(Long a, Long b) {
        long from = Math.min(a, b);
        long to = Math.max(a, b);
        return contactTraceRepository.findByFarmIdOrderByLastContactAtDesc(FARM_ID).stream()
                .filter(t -> t.getFromLivestockId() == from && t.getToLivestockId() == to)
                .toList();
    }

    private Instant cutoff() {
        return base.minusSeconds(60);
    }

    // ── Tests ────────────────────────────────────────────────────────

    @Test
    @DisplayName("两牛交错轨迹产生接触行，距离/时长/评分字段合理")
    void interleavedTrajectoriesProduceContactRow() {
        Cow a = insertCow("A");
        Cow b = insertCow("B");
        track(a, 0, 10);
        // Interleaved movement: far -> 10..14m for 6 minutes -> far again.
        int[] offsets = {200, 10, 12, 10, 14, 10, 10, 150, 210, 240};
        for (int k = 0; k < offsets.length; k++) {
            insertGps(b.deviceId(), BASE_LAT + offsets[k] / METERS_PER_DEG_LAT, BASE_LNG,
                    base.plusSeconds(60L * k));
        }
        buildService(a, b);

        int written = service.analyzeAndStore(FARM_ID, null, cutoff());

        assertThat(written).isEqualTo(1);
        List<ContactTrace> rows = rowsFor(a.livestockId(), b.livestockId());
        assertThat(rows).hasSize(1);
        ContactTrace row = rows.get(0);
        // Direction normalized: smaller livestockId is `from`.
        assertThat(row.getFromLivestockId()).isLessThan(row.getToLivestockId());
        assertThat(row.getProximityMeters()).isBetween(new BigDecimal("9.5"), new BigDecimal("10.5"));
        assertThat(row.getContactDurationMinutes()).isEqualTo(6);
        // 40 (contact < 24h ago) + 25 (min distance < 15m) + 10 (duration > 5min) = 75, HIGH
        assertThat(row.getRiskScore()).isEqualTo(75);
        assertThat(row.getRiskLevel()).isEqualTo("HIGH");
        assertThat(row.getDiseaseType()).isNull();
        assertThat(row.getMarkedAt()).isNull();
        assertThat(row.getLastContactAt())
                .isAfter(base.plusSeconds(60L * 5))
                .isBefore(base.plusSeconds(60L * 7));
    }

    @Test
    @DisplayName("距离阈值边界：29m 计接触，31m 不计")
    void distanceThresholdBoundary() {
        Cow a = insertCow("A");
        Cow b = insertCow("B");
        Cow c = insertCow("C");
        track(a, 0, 10);
        track(b, 29, 10);   // 29m north of A -> within threshold
        track(c, -31, 10);  // 31m south of A -> beyond threshold (B..C = 60m apart)
        buildService(a, b, c);

        int written = service.analyzeAndStore(FARM_ID, null, cutoff());

        assertThat(written).isEqualTo(1);
        assertThat(rowsFor(a.livestockId(), b.livestockId())).hasSize(1);
        assertThat(rowsFor(a.livestockId(), c.livestockId())).isEmpty();
        assertThat(rowsFor(b.livestockId(), c.livestockId())).isEmpty();
    }

    @Test
    @DisplayName("时长阈值边界：累计 4min 不计，6min 计")
    void durationThresholdBoundary() {
        Cow a = insertCow("A");
        Cow b = insertCow("B");
        Cow c = insertCow("C");
        track(a, 0, 12);
        track(b, 20, 4);   // 4 minutes at 20m -> below the 5-minute minimum
        track(c, -20, 6);  // 6 minutes at 20m -> counts (B..C = 40m apart)
        buildService(a, b, c);

        int written = service.analyzeAndStore(FARM_ID, null, cutoff());

        assertThat(written).isEqualTo(1);
        assertThat(rowsFor(a.livestockId(), b.livestockId())).isEmpty();
        List<ContactTrace> acRows = rowsFor(a.livestockId(), c.livestockId());
        assertThat(acRows).hasSize(1);
        assertThat(acRows.get(0).getContactDurationMinutes()).isEqualTo(6);
    }

    @Test
    @DisplayName("已标记行（marked_at 非空）不被分析覆盖")
    void markedRowsAreNotOverwritten() {
        Cow a = insertCow("A");
        Cow b = insertCow("B");
        track(a, 0, 10);
        track(b, 10, 6);   // would produce a fresh contact row...
        long from = Math.min(a.livestockId(), b.livestockId());
        long to = Math.max(a.livestockId(), b.livestockId());
        // ...except the pair already carries a MARKED row with sentinel values.
        entityManager.createNativeQuery("""
                        INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id,
                            proximity_meters, contact_duration_minutes, last_contact_at,
                            disease_type, marked_at, risk_score, risk_level)
                        VALUES (?, ?, ?, 99.9, 999, NOW(), '口蹄疫疑似', NOW(), 82, 'HIGH')
                        """)
                .setParameter(1, FARM_ID).setParameter(2, from).setParameter(3, to)
                .executeUpdate();
        buildService(a, b);

        int written = service.analyzeAndStore(FARM_ID, null, cutoff());

        assertThat(written).isZero();
        List<ContactTrace> rows = rowsFor(a.livestockId(), b.livestockId());
        assertThat(rows).hasSize(1);
        ContactTrace row = rows.get(0);
        assertThat(row.getProximityMeters()).isEqualByComparingTo("99.9");
        assertThat(row.getContactDurationMinutes()).isEqualTo(999);
        assertThat(row.getRiskScore()).isEqualTo(82);
        assertThat(row.getRiskLevel()).isEqualTo("HIGH");
        assertThat(row.getDiseaseType()).isEqualTo("口蹄疫疑似");
        assertThat(row.getMarkedAt()).isNotNull();
    }

    @Test
    @DisplayName("重复分析幂等：不产生重复行，迟到轨迹数值刷新")
    void reAnalysisIsIdempotentAndRefreshes() {
        Cow a = insertCow("A");
        Cow b = insertCow("B");
        track(a, 0, 6);
        track(b, 10, 6);
        buildService(a, b);

        int first = service.analyzeAndStore(FARM_ID, null, cutoff());
        assertThat(first).isEqualTo(1);
        Long rowId = rowsFor(a.livestockId(), b.livestockId()).get(0).getId();

        int second = service.analyzeAndStore(FARM_ID, null, cutoff());
        assertThat(second).isEqualTo(1);   // refresh of the same row counts as a write
        List<ContactTrace> rows = rowsFor(a.livestockId(), b.livestockId());
        assertThat(rows).hasSize(1);       // no duplicate row
        assertThat(rows.get(0).getId()).isEqualTo(rowId);
        assertThat(rows.get(0).getContactDurationMinutes()).isEqualTo(6);

        // Late GPS frames arrive -> rolling re-computation refreshes the values.
        for (int k = 6; k < 9; k++) {
            insertGps(a.deviceId(), BASE_LAT, BASE_LNG, base.plusSeconds(60L * k));
            insertGps(b.deviceId(), BASE_LAT + 10 / METERS_PER_DEG_LAT, BASE_LNG,
                    base.plusSeconds(60L * k));
        }
        int third = service.analyzeAndStore(FARM_ID, null, cutoff());
        assertThat(third).isEqualTo(1);
        rows = rowsFor(a.livestockId(), b.livestockId());
        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getId()).isEqualTo(rowId);
        assertThat(rows.get(0).getContactDurationMinutes()).isEqualTo(9);
    }

    @Test
    @DisplayName("指定 livestockId 时只分析该牛参与的牛对")
    void targetedAnalysisOnlyCoversTargetPairs() {
        Cow a = insertCow("A");
        Cow b = insertCow("B");
        Cow c = insertCow("C");
        track(a, 0, 10);
        track(b, 10, 10);
        track(c, -10, 10);   // A-B 10m, A-C 10m, B-C 20m — all within threshold
        buildService(a, b, c);

        int written = service.analyzeAndStore(FARM_ID, b.livestockId(), cutoff());

        assertThat(written).isEqualTo(2);   // (A,B) + (B,C)
        assertThat(rowsFor(a.livestockId(), b.livestockId())).hasSize(1);
        assertThat(rowsFor(b.livestockId(), c.livestockId())).hasSize(1);
        assertThat(rowsFor(a.livestockId(), c.livestockId())).isEmpty();
    }
}
