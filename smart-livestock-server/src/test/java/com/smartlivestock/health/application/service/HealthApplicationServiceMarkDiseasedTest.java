package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.MarkDiseaseRequest;
import com.smartlivestock.health.application.dto.HealthDtos.MarkDiseaseResponse;
import com.smartlivestock.health.domain.model.ContactTrace;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.EstrusScoreRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import com.smartlivestock.health.domain.service.DigestiveAnalysisService;
import com.smartlivestock.health.domain.service.EpidemicAnalysisService;
import com.smartlivestock.health.domain.service.EstrusAnalysisService;
import com.smartlivestock.health.domain.service.FeverAnalysisService;
import com.smartlivestock.health.infrastructure.persistence.jpa.EpidemicDispositionJpaRepository;
import com.smartlivestock.health.interfaces.app.EpidemicController;
import com.smartlivestock.ranch.application.signal.SignalRevisionService;
import com.smartlivestock.shared.common.MessageResolver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Pure-JVM tests for the two-phase markDiseased (instant track, plan Task 3).
 * The analysis kernel is mocked so these tests pin the marking semantics:
 * direction boundary (target holding the larger id), contactsGenerated
 * passthrough, window clamping, re-mark refresh and the controller-level
 * no-GPS warning. Source resolution is verified against the REAL
 * {@link EpidemicWorkbenchService} (unmodified from-based logic) on top of
 * an in-memory repository. Real-database guarantees for the kernel itself
 * live in {@code ContactAnalysisServiceIntegrationTest}.
 */
class HealthApplicationServiceMarkDiseasedTest {

    private static final long FARM_ID = 1L;

    private final InMemoryContactTraceRepository contactTraceRepo = new InMemoryContactTraceRepository();
    private final ContactAnalysisService contactAnalysisService = mock(ContactAnalysisService.class);
    private final RanchQueryPort ranchQueryPort = mock(RanchQueryPort.class);
    private final HealthSnapshotRepository snapshotRepo = mock(HealthSnapshotRepository.class);
    private final EpidemicDispositionJpaRepository dispositionRepo = mock(EpidemicDispositionJpaRepository.class);

    private HealthApplicationService service;
    private EpidemicWorkbenchService workbenchService;

    @BeforeEach
    void setUp() {
        service = new HealthApplicationService(
                snapshotRepo,
                mock(TemperatureLogRepository.class),
                mock(RumenMotilityLogRepository.class),
                mock(ActivityLogRepository.class),
                mock(EstrusScoreRepository.class),
                contactTraceRepo,
                ranchQueryPort,
                mock(RanchCommandPort.class),
                mock(HealthSubscriptionPort.class),
                mock(HealthAnomalyService.class),
                mock(HealthAlertBridgeService.class),
                mock(SignalRevisionService.class),
                mock(FeverAnalysisService.class),
                mock(DigestiveAnalysisService.class),
                mock(EstrusAnalysisService.class),
                mock(EpidemicAnalysisService.class),
                mock(MessageResolver.class),
                contactAnalysisService);
        ReflectionTestUtils.setField(service, "analysisWindowHours", 72);

        EpidemicAnalysisService metricsService = mock(EpidemicAnalysisService.class);
        when(metricsService.calculateHerdMetrics(any())).thenReturn(new EpidemicAnalysisService.HerdMetrics(
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, 0, 0));
        when(metricsService.assessRiskLevel(any())).thenReturn("LOW");
        workbenchService = new EpidemicWorkbenchService(
                contactTraceRepo, snapshotRepo, ranchQueryPort, metricsService, dispositionRepo);
        ReflectionTestUtils.setField(workbenchService, "criticalRisk", 70);
        ReflectionTestUtils.setField(workbenchService, "criticalNoHealthRisk", 80);
        ReflectionTestUtils.setField(workbenchService, "observationRisk", 40);

        when(ranchQueryPort.findLivestockById(anyLong())).thenAnswer(invocation ->
                Optional.of(new LivestockInfo(invocation.getArgument(0), FARM_ID,
                        "CT-" + invocation.getArgument(0), "FEMALE", "test")));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(anyLong(), anyCollection()))
                .thenReturn(List.of());
        when(snapshotRepo.findByFarmId(anyLong())).thenReturn(List.of());
        when(dispositionRepo.findByFarmIdAndStatusIn(anyLong(), anyCollection())).thenReturn(List.of());
    }

    /** A kernel-normalized pool row (min(id)=from), unmarked. */
    private ContactTrace poolRow(Long from, Long to) {
        ContactTrace row = new ContactTrace();
        row.setFarmId(FARM_ID);
        row.setFromLivestockId(from);
        row.setToLivestockId(to);
        row.setProximityMeters(new BigDecimal("12.5"));
        row.setContactDurationMinutes(8);
        row.setLastContactAt(Instant.now().minus(Duration.ofMinutes(30)));
        row.setRiskScore(65);
        row.setRiskLevel("MEDIUM");
        contactTraceRepo.save(row);
        return row;
    }

    // ── Direction boundary (the key edge of Task 3) ────────────────

    @Test
    @DisplayName("target id 较大：参与行翻转成 from=target 后标记，工作台解析出 target 为源头")
    void targetWithLargerIdIsFlippedAndResolvedAsSource() {
        poolRow(11L, 22L);   // kernel normalization put the partner (11) on the from side
        when(contactAnalysisService.analyzeAndStore(eq(FARM_ID), eq(22L), any())).thenReturn(1);

        HealthApplicationService.MarkDiseasedResult result =
                service.markDiseased(FARM_ID, 22L, "牛结核疑似", null);

        assertThat(result.contactsGenerated()).isEqualTo(1);
        assertThat(contactTraceRepo.rows).hasSize(1);
        ContactTrace row = contactTraceRepo.rows.get(0);
        assertThat(row.getFromLivestockId()).isEqualTo(22L);   // flipped to the marked source
        assertThat(row.getToLivestockId()).isEqualTo(11L);
        assertThat(row.getDiseaseType()).isEqualTo("牛结核疑似");
        assertThat(row.getMarkedAt()).isNotNull();

        // The workbench's from-based resolution (latestMarkedSource + markedTrace,
        // both unchanged) deterministically resolves the marked target.
        var response = workbenchService.workbench(FARM_ID, null, 72, 2, null);
        assertThat(response.context().source().livestockId()).isEqualTo("22");
        assertThat(response.context().source().status()).isEqualTo("SUSPECTED");
        assertThat(response.context().source().diseaseType()).isEqualTo("牛结核疑似");
        assertThat(response.context().source().markedAt()).isNotNull();
        assertThat(response.network().sourceLivestockId()).isEqualTo("22");
    }

    @Test
    @DisplayName("target id 较小（对称场景）：行方向不变原地标记，工作台解析出 target")
    void targetWithSmallerIdIsMarkedInPlace() {
        poolRow(11L, 22L);
        when(contactAnalysisService.analyzeAndStore(eq(FARM_ID), eq(11L), any())).thenReturn(1);

        service.markDiseased(FARM_ID, 11L, "口蹄疫疑似", null);

        ContactTrace row = contactTraceRepo.rows.get(0);
        assertThat(row.getFromLivestockId()).isEqualTo(11L);   // no flip needed
        assertThat(row.getToLivestockId()).isEqualTo(22L);
        assertThat(row.getDiseaseType()).isEqualTo("口蹄疫疑似");
        assertThat(row.getMarkedAt()).isNotNull();

        var response = workbenchService.workbench(FARM_ID, null, 72, 2, null);
        assertThat(response.context().source().livestockId()).isEqualTo("11");
        assertThat(response.context().source().status()).isEqualTo("SUSPECTED");
    }

    @Test
    @DisplayName("所有参与行（from/to=target）都标记，无关行不动，contactsGenerated 透传")
    void allParticipatingRowsAreMarkedAndUnrelatedRowsUntouched() {
        ContactTrace smaller = poolRow(11L, 22L);   // to = target -> flip
        ContactTrace larger = poolRow(22L, 33L);    // from = target -> in place
        ContactTrace unrelated = poolRow(33L, 44L);
        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(2);

        HealthApplicationService.MarkDiseasedResult result =
                service.markDiseased(FARM_ID, 22L, "布病疑似", null);

        assertThat(result.contactsGenerated()).isEqualTo(2);
        assertThat(smaller.getFromLivestockId()).isEqualTo(22L);
        assertThat(smaller.getToLivestockId()).isEqualTo(11L);
        assertThat(larger.getFromLivestockId()).isEqualTo(22L);
        assertThat(larger.getToLivestockId()).isEqualTo(33L);
        assertThat(smaller.getMarkedAt()).isNotNull();
        assertThat(smaller.getDiseaseType()).isEqualTo("布病疑似");
        assertThat(larger.getMarkedAt()).isNotNull();
        assertThat(unrelated.getMarkedAt()).isNull();
        assertThat(unrelated.getDiseaseType()).isNull();
        assertThat(unrelated.getFromLivestockId()).isEqualTo(33L);   // untouched
    }

    // ── Window clamping ────────────────────────────────────────────

    @Test
    @DisplayName("windowHours 钳制：null/0→默认 72h，800→720h，5→透传")
    void windowHoursClamping() {
        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(0);

        service.markDiseased(FARM_ID, 22L, "x", null);   // default (configured 72h)
        service.markDiseased(FARM_ID, 22L, "x", 0);      // 0 -> default
        service.markDiseased(FARM_ID, 22L, "x", 800);    // clamped to 720h
        service.markDiseased(FARM_ID, 22L, "x", 5);      // passthrough

        ArgumentCaptor<Instant> cutoff = ArgumentCaptor.forClass(Instant.class);
        verify(contactAnalysisService, times(4)).analyzeAndStore(eq(FARM_ID), eq(22L), cutoff.capture());
        List<Instant> windows = cutoff.getAllValues();
        assertWindowHours(windows.get(0), 72);
        assertWindowHours(windows.get(1), 72);
        assertWindowHours(windows.get(2), 720);
        assertWindowHours(windows.get(3), 5);
    }

    private static void assertWindowHours(Instant cutoff, long expectedHours) {
        assertThat(Duration.between(cutoff, Instant.now()))
                .isCloseTo(Duration.ofHours(expectedHours), Duration.ofSeconds(60));
    }

    // ── Re-mark and no-GPS ─────────────────────────────────────────

    @Test
    @DisplayName("重复标记=重算再标记：markedAt 刷新、病种更新、分析被再次调用")
    void reMarkRerunsAnalysisAndRefreshesMarkedAt() throws InterruptedException {
        ContactTrace row = poolRow(11L, 22L);
        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(1, 2);

        HealthApplicationService.MarkDiseasedResult first =
                service.markDiseased(FARM_ID, 22L, "牛结核疑似", null);
        Instant firstMarkedAt = row.getMarkedAt();
        assertThat(first.contactsGenerated()).isEqualTo(1);

        Thread.sleep(5L);   // guarantee a strictly later markedAt stamp

        HealthApplicationService.MarkDiseasedResult second =
                service.markDiseased(FARM_ID, 22L, "腹泻类疾病", null);

        assertThat(second.contactsGenerated()).isEqualTo(2);
        assertThat(row.getMarkedAt()).isAfter(firstMarkedAt);
        assertThat(row.getDiseaseType()).isEqualTo("腹泻类疾病");
        assertThat(row.getFromLivestockId()).isEqualTo(22L);   // still the marked source
        verify(contactAnalysisService, times(2)).analyzeAndStore(anyLong(), anyLong(), any());
    }

    @Test
    @DisplayName("窗口内无 GPS：contactsGenerated=0，标记仍成功且不产生行")
    void noGpsWindowReturnsZeroAndMarksNothing() {
        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(0);

        HealthApplicationService.MarkDiseasedResult result =
                service.markDiseased(FARM_ID, 22L, "牛结核疑似", null);

        assertThat(result.contactsGenerated()).isZero();
        assertThat(contactTraceRepo.rows).isEmpty();
    }

    // ── unmark unchanged ───────────────────────────────────────────

    @Test
    @DisplayName("unmarkDiseased 行为不变：清空 from=target 行的病种/标记时间")
    void unmarkClearsMarkingOnFromRows() {
        ContactTrace row = poolRow(11L, 22L);
        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(1);
        service.markDiseased(FARM_ID, 22L, "牛结核疑似", null);
        assertThat(row.getMarkedAt()).isNotNull();

        service.unmarkDiseased(FARM_ID, 22L);

        assertThat(row.getDiseaseType()).isNull();
        assertThat(row.getMarkedAt()).isNull();
        assertThat(row.getFromLivestockId()).isEqualTo(22L);   // marking-only semantics
    }

    // ── Controller response contract ───────────────────────────────

    @Test
    @DisplayName("contactsGenerated=0 时响应附 error.epidemicNoGpsWindow 提示码，>0 时无提示")
    void controllerAttachesNoGpsWarningOnlyOnZeroContacts() {
        EpidemicController controller = new EpidemicController(service, workbenchService);

        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(0);
        var empty = controller.markDiseased(FARM_ID, new MarkDiseaseRequest(22L, "牛结核疑似", null));
        MarkDiseaseResponse emptyBody = empty.getBody().getData();
        assertThat(empty.getStatusCode().value()).isEqualTo(200);
        assertThat(emptyBody.contactsGenerated()).isZero();
        assertThat(emptyBody.warning()).isEqualTo("error.epidemicNoGpsWindow");

        poolRow(11L, 22L);
        when(contactAnalysisService.analyzeAndStore(anyLong(), anyLong(), any())).thenReturn(1);
        var marked = controller.markDiseased(FARM_ID, new MarkDiseaseRequest(22L, "牛结核疑似", 120));
        MarkDiseaseResponse markedBody = marked.getBody().getData();
        assertThat(marked.getStatusCode().value()).isEqualTo(200);
        assertThat(markedBody.contactsGenerated()).isEqualTo(1);
        assertThat(markedBody.warning()).isNull();
    }

    // ── In-memory fake (mirrors the ContactAnalysisServiceTest one) ──

    private static final class InMemoryContactTraceRepository
            implements com.smartlivestock.health.domain.repository.ContactTraceRepository {
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
}
