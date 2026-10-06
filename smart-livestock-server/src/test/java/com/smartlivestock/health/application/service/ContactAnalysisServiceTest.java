package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.ContactTrace;
import com.smartlivestock.health.domain.port.GpsTrajectoryPort;
import com.smartlivestock.health.domain.port.GpsTrajectoryPort.GpsPoint;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.ContactTraceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Pure-JVM companion of {@link ContactAnalysisServiceIntegrationTest}: same
 * scenario matrix (interleaved trajectories, threshold boundaries, marked-row
 * protection, idempotency, targeted scope) executed against in-memory fakes.
 * The integration test adds the real-database guarantee (Testcontainers);
 * this one runs everywhere and pins the kernel logic.
 */
class ContactAnalysisServiceTest {

    private static final long FARM_ID = 1L;
    private static final double BASE_LAT = 28.0d;
    private static final double BASE_LNG = 113.0d;
    /** Meters per degree of latitude under the haversine constant (R = 6,371 km). */
    private static final double METERS_PER_DEG_LAT = Math.PI / 180.0d * 6_371_000.0d;

    private final InMemoryContactTraceRepository contactTraceRepo = new InMemoryContactTraceRepository();
    private final FakeGpsTrajectoryPort gpsPort = new FakeGpsTrajectoryPort();
    private ContactAnalysisService service;

    private Instant base;

    @BeforeEach
    void setUp() {
        base = Instant.now().minus(Duration.ofMinutes(30));
        RanchQueryPort ranchPort = mock(RanchQueryPort.class);
        when(ranchPort.findAllByFarmId(anyLong())).thenReturn(List.of());
        // Defaults: proximity 30m, minimum duration 5min, 60s alignment buckets.
        service = new ContactAnalysisService(contactTraceRepo, gpsPort, ranchPort, 30.0d, 5, 60L);
    }

    private void herd(Long... livestockIds) {
        RanchQueryPort ranchPort = mock(RanchQueryPort.class);
        when(ranchPort.findAllByFarmId(anyLong())).thenReturn(
                java.util.Arrays.stream(livestockIds)
                        .map(id -> new LivestockInfo(id, FARM_ID, "CT-" + id, "FEMALE", "test"))
                        .toList());
        service = new ContactAnalysisService(contactTraceRepo, gpsPort, ranchPort, 30.0d, 5, 60L);
    }

    /** One fix per minute at a constant latitude offset (meters) from the base point. */
    private void track(long livestockId, double offsetMeters, int minutes) {
        for (int k = 0; k < minutes; k++) {
            gpsPort.add(livestockId, BASE_LAT + offsetMeters / METERS_PER_DEG_LAT, BASE_LNG,
                    base.plusSeconds(60L * k));
        }
    }

    private List<ContactTrace> rowsFor(Long a, Long b) {
        long from = Math.min(a, b);
        long to = Math.max(a, b);
        return contactTraceRepo.rows.stream()
                .filter(t -> t.getFromLivestockId() == from && t.getToLivestockId() == to)
                .toList();
    }

    // ── Tests ────────────────────────────────────────────────────────

    @Test
    @DisplayName("两牛交错轨迹产生接触行，距离/时长/评分字段合理")
    void interleavedTrajectoriesProduceContactRow() {
        track(11L, 0, 10);
        // Interleaved movement: far -> 10..14m for 6 minutes -> far again.
        int[] offsets = {200, 10, 12, 10, 14, 10, 10, 150, 210, 240};
        for (int k = 0; k < offsets.length; k++) {
            gpsPort.add(22L, BASE_LAT + offsets[k] / METERS_PER_DEG_LAT, BASE_LNG,
                    base.plusSeconds(60L * k));
        }
        herd(11L, 22L);

        int written = service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60));

        assertThat(written).isEqualTo(1);
        List<ContactTrace> rows = rowsFor(11L, 22L);
        assertThat(rows).hasSize(1);
        ContactTrace row = rows.get(0);
        assertThat(row.getFromLivestockId()).isEqualTo(11L);   // smaller id = from
        assertThat(row.getToLivestockId()).isEqualTo(22L);
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
        track(11L, 0, 10);
        track(22L, 29, 10);   // 29m north -> within threshold
        track(33L, -31, 10);  // 31m south -> beyond threshold (22..33 = 60m apart)
        herd(11L, 22L, 33L);

        int written = service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60));

        assertThat(written).isEqualTo(1);
        assertThat(rowsFor(11L, 22L)).hasSize(1);
        assertThat(rowsFor(11L, 33L)).isEmpty();
        assertThat(rowsFor(22L, 33L)).isEmpty();
    }

    @Test
    @DisplayName("时长阈值边界：累计 4min 不计，6min 计")
    void durationThresholdBoundary() {
        track(11L, 0, 12);
        track(22L, 20, 4);   // 4 minutes at 20m -> below the 5-minute minimum
        track(33L, -20, 6);  // 6 minutes at 20m -> counts (22..33 = 40m apart)
        herd(11L, 22L, 33L);

        int written = service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60));

        assertThat(written).isEqualTo(1);
        assertThat(rowsFor(11L, 22L)).isEmpty();
        List<ContactTrace> rows = rowsFor(11L, 33L);
        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getContactDurationMinutes()).isEqualTo(6);
    }

    @Test
    @DisplayName("已标记行（markedAt 非空）不被分析覆盖")
    void markedRowsAreNotOverwritten() {
        track(11L, 0, 10);
        track(22L, 10, 6);
        ContactTrace marked = new ContactTrace();
        marked.setFarmId(FARM_ID);
        marked.setFromLivestockId(11L);
        marked.setToLivestockId(22L);
        marked.setProximityMeters(new BigDecimal("99.9"));
        marked.setContactDurationMinutes(999);
        marked.setLastContactAt(base);
        marked.setDiseaseType("口蹄疫疑似");
        marked.setMarkedAt(Instant.now());
        marked.setRiskScore(82);
        marked.setRiskLevel("HIGH");
        contactTraceRepo.save(marked);
        herd(11L, 22L);

        int written = service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60));

        assertThat(written).isZero();
        List<ContactTrace> rows = rowsFor(11L, 22L);
        assertThat(rows).hasSize(1);
        ContactTrace row = rows.get(0);
        assertThat(row.getProximityMeters()).isEqualByComparingTo("99.9");
        assertThat(row.getContactDurationMinutes()).isEqualTo(999);
        assertThat(row.getRiskScore()).isEqualTo(82);
        assertThat(row.getDiseaseType()).isEqualTo("口蹄疫疑似");
        assertThat(row.getMarkedAt()).isNotNull();
    }

    @Test
    @DisplayName("重复分析幂等：不产生重复行，迟到轨迹数值刷新")
    void reAnalysisIsIdempotentAndRefreshes() {
        track(11L, 0, 6);
        track(22L, 10, 6);
        herd(11L, 22L);

        assertThat(service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60))).isEqualTo(1);
        Long rowId = rowsFor(11L, 22L).get(0).getId();

        assertThat(service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60))).isEqualTo(1);
        List<ContactTrace> rows = rowsFor(11L, 22L);
        assertThat(rows).hasSize(1);                        // no duplicate row
        assertThat(rows.get(0).getId()).isEqualTo(rowId);   // same row refreshed
        assertThat(rows.get(0).getContactDurationMinutes()).isEqualTo(6);

        // Late GPS frames arrive -> rolling re-computation refreshes the values.
        for (int k = 6; k < 9; k++) {
            gpsPort.add(11L, BASE_LAT, BASE_LNG, base.plusSeconds(60L * k));
            gpsPort.add(22L, BASE_LAT + 10 / METERS_PER_DEG_LAT, BASE_LNG, base.plusSeconds(60L * k));
        }
        assertThat(service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60))).isEqualTo(1);
        rows = rowsFor(11L, 22L);
        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getId()).isEqualTo(rowId);
        assertThat(rows.get(0).getContactDurationMinutes()).isEqualTo(9);
    }

    @Test
    @DisplayName("指定 livestockId 时只分析该牛参与的牛对")
    void targetedAnalysisOnlyCoversTargetPairs() {
        track(11L, 0, 10);
        track(22L, 10, 10);
        track(33L, -10, 10);   // 11-22: 10m, 11-33: 10m, 22-33: 20m — all within threshold
        herd(11L, 22L, 33L);

        int written = service.analyzeAndStore(FARM_ID, 22L, base.minusSeconds(60));

        assertThat(written).isEqualTo(2);   // (11,22) + (22,33)
        assertThat(rowsFor(11L, 22L)).hasSize(1);
        assertThat(rowsFor(22L, 33L)).hasSize(1);
        assertThat(rowsFor(11L, 33L)).isEmpty();
    }

    @Test
    @DisplayName("markDiseased 翻转后的已标记行：重分析不重复插入且疫情语义保留")
    void flippedMarkedRowIsNotDuplicatedByReAnalysis() {
        track(11L, 0, 10);
        track(22L, 10, 6);
        herd(11L, 22L);
        assertThat(service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60))).isEqualTo(1);
        ContactTrace poolRow = rowsFor(11L, 22L).get(0);
        Long rowId = poolRow.getId();

        // Simulate the mark-diseased claim of the LARGER id (22): the row is
        // flipped so from = marked source, then stamped with epidemic fields.
        poolRow.setFromLivestockId(22L);
        poolRow.setToLivestockId(11L);
        poolRow.setDiseaseType("牛结核疑似");
        poolRow.setMarkedAt(Instant.now());

        int written = service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60));

        assertThat(written).isZero();                       // marked row skipped, no duplicate
        assertThat(contactTraceRepo.rows).hasSize(1);
        ContactTrace row = contactTraceRepo.rows.get(0);
        assertThat(row.getId()).isEqualTo(rowId);
        assertThat(row.getFromLivestockId()).isEqualTo(22L); // flip + marking untouched
        assertThat(row.getToLivestockId()).isEqualTo(11L);
        assertThat(row.getDiseaseType()).isEqualTo("牛结核疑似");
        assertThat(row.getMarkedAt()).isNotNull();
    }

    @Test
    @DisplayName("未标记的翻转行：重分析复用同一行并归一回 min(id)=from 方向")
    void unmarkedFlippedRowIsReusedAndRenormalized() {
        track(11L, 0, 10);
        track(22L, 10, 6);
        herd(11L, 22L);
        assertThat(service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60))).isEqualTo(1);
        ContactTrace poolRow = rowsFor(11L, 22L).get(0);
        Long rowId = poolRow.getId();

        // Simulate the post-unmark state: marking cleared but the mark-time
        // flip was left behind (from = 22, the larger id).
        poolRow.setFromLivestockId(22L);
        poolRow.setToLivestockId(11L);
        poolRow.setDiseaseType(null);
        poolRow.setMarkedAt(null);

        int written = service.analyzeAndStore(FARM_ID, null, base.minusSeconds(60));

        assertThat(written).isEqualTo(1);                   // refreshed, not inserted
        assertThat(contactTraceRepo.rows).hasSize(1);
        ContactTrace row = contactTraceRepo.rows.get(0);
        assertThat(row.getId()).isEqualTo(rowId);           // same row reused
        assertThat(row.getFromLivestockId()).isEqualTo(11L); // direction re-normalized
        assertThat(row.getToLivestockId()).isEqualTo(22L);
        assertThat(row.getContactDurationMinutes()).isEqualTo(6);
    }

    // ── Fakes ────────────────────────────────────────────────────────

    /** Minimal in-memory stand-in mirroring JPA save/merge semantics. */
    private static final class InMemoryContactTraceRepository implements ContactTraceRepository {
        final List<ContactTrace> rows = new ArrayList<>();
        private long seq = 1;

        @Override
        public List<ContactTrace> findByFarmIdOrderByLastContactAtDesc(Long farmId) {
            return rows.stream()
                    .filter(r -> farmId.equals(r.getFarmId()))
                    .sorted(Comparator.comparing(ContactTrace::getLastContactAt,
                            Comparator.nullsLast(Comparator.reverseOrder())))
                    .toList();
        }

        @Override
        public List<ContactTrace> findByFromLivestockIdOrderByLastContactAtDesc(Long fromLivestockId) {
            return rows.stream()
                    .filter(r -> fromLivestockId.equals(r.getFromLivestockId()))
                    .toList();
        }

        @Override
        public List<ContactTrace> findByFarmIdAndLivestockParticipation(Long farmId, Long livestockId) {
            return rows.stream()
                    .filter(r -> farmId.equals(r.getFarmId()))
                    .filter(r -> livestockId.equals(r.getFromLivestockId())
                            || livestockId.equals(r.getToLivestockId()))
                    .toList();
        }

        @Override
        public boolean existsMarkedSourceByFarmId(Long farmId) {
            return rows.stream()
                    .filter(r -> farmId.equals(r.getFarmId()))
                    .anyMatch(r -> r.getMarkedAt() != null);
        }

        @Override
        public ContactTrace save(ContactTrace trace) {
            if (trace.getId() == null) {
                trace.setId(seq++);
                trace.setCreatedAt(Instant.now());
                rows.add(trace);
            }
            return trace;
        }
    }

    private static final class FakeGpsTrajectoryPort implements GpsTrajectoryPort {
        private final Map<Long, List<GpsPoint>> trajectories = new HashMap<>();

        void add(long livestockId, double lat, double lng, Instant at) {
            trajectories.computeIfAbsent(livestockId, k -> new ArrayList<>())
                    .add(new GpsPoint(at, lat, lng));
        }

        @Override
        public List<GpsPoint> findTrajectory(Long livestockId, Instant from, Instant to) {
            return trajectories.getOrDefault(livestockId, List.of()).stream()
                    .filter(p -> !p.recordedAt().isBefore(from) && !p.recordedAt().isAfter(to))
                    .toList();
        }
    }
}
