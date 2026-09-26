package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.HealthOverviewResponse;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.*;
import com.smartlivestock.health.domain.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * NIX-245 overview fixes: healthyRate denominator alignment (the >100% bug),
 * watch states count as healthy (user ruling), estrus high score from CURRENT
 * snapshots, per-scene active ticket counts from the same query as the alert
 * center (reconciliation source).
 */
@ExtendWith(MockitoExtension.class)
class HealthOverviewFixesTest {

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private TemperatureLogRepository tempLogRepo;
    @Mock private RumenMotilityLogRepository motilityLogRepo;
    @Mock private ActivityLogRepository activityLogRepo;
    @Mock private EstrusScoreRepository estrusScoreRepo;
    @Mock private ContactTraceRepository contactTraceRepo;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private HealthSubscriptionPort subscriptionPort;
    @Mock private HealthAnomalyService healthAnomalyService;
    @Mock private HealthAlertBridgeService healthAlertBridgeService;
    @Mock private FeverAnalysisService feverService;
    @Mock private DigestiveAnalysisService digestiveService;
    @Mock private EstrusAnalysisService estrusAnalysisService;
    @Mock private com.smartlivestock.shared.common.MessageResolver messageResolver;

    private EpidemicAnalysisService epidemicService = new EpidemicAnalysisService();
    private HealthApplicationService service;

    @BeforeEach
    void setUp() {
        service = new HealthApplicationService(snapshotRepo, tempLogRepo, motilityLogRepo,
                activityLogRepo, estrusScoreRepo, contactTraceRepo, ranchQueryPort,
                ranchCommandPort, subscriptionPort, healthAnomalyService, healthAlertBridgeService,
                feverService, digestiveService, estrusAnalysisService, epidemicService,
                messageResolver);
        lenient().when(ranchQueryPort.countActiveAlertsByFarmId(1L)).thenReturn(0);
        lenient().when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(eq(1L), anyCollection()))
                .thenReturn(List.of());
        lenient().when(ranchQueryPort.findLivestockById(org.mockito.ArgumentMatchers.anyLong()))
                .thenReturn(java.util.Optional.empty());
    }

    private HealthSnapshot snap(long id, TempStatus temp, MotilityStatus motility, Integer estrus) {
        HealthSnapshot s = new HealthSnapshot();
        s.setLivestockId(id);
        s.setFarmId(1L);
        s.setTempStatus(temp);
        s.setMotilityStatus(motility);
        s.setEstrusScore(estrus);
        s.setAiAnomalyScore(BigDecimal.valueOf(0.04));
        return s;
    }

    @Test
    void healthyRateNeverExceedsOne_andWatchStatesCountHealthy() {
        // 4 current livestock; snapshot for #99 belongs to a removed livestock
        // (the old code counted it into the numerator → 105%).
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(
                new LivestockInfo(4L, 1L, "A", "F", "B"),
                new LivestockInfo(8L, 1L, "B", "F", "B"),
                new LivestockInfo(16L, 1L, "C", "F", "B"),
                new LivestockInfo(20L, 1L, "D", "F", "B")));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snap(4, TempStatus.FEVER, MotilityStatus.NORMAL, null),      // abnormal
                snap(8, TempStatus.ELEVATED, MotilityStatus.NORMAL, null),   // watch → healthy (ruling)
                snap(16, TempStatus.NORMAL, MotilityStatus.LOW, null),       // watch → healthy (ruling)
                snap(99, TempStatus.NORMAL, MotilityStatus.NORMAL, null)));  // orphan snapshot, ignored

        HealthOverviewResponse res = service.getOverview(1L);

        // abnormal = 1 (livestock 4); healthy = 3/4 = 0.75
        assertThat(res.stats().healthyRate()).isEqualTo(0.75);
    }

    @Test
    void feverAbnormalIncludesElevatedAndCarriesTicketCount() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(
                new LivestockInfo(4L, 1L, "A", "F", "B"),
                new LivestockInfo(8L, 1L, "B", "F", "B"),
                new LivestockInfo(16L, 1L, "C", "F", "B")));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snap(4, TempStatus.CRITICAL, MotilityStatus.NORMAL, null),
                snap(8, TempStatus.ELEVATED, MotilityStatus.NORMAL, null),
                snap(16, TempStatus.NORMAL, MotilityStatus.NORMAL, 82)));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(eq(1L), anyCollection()))
                .thenReturn(List.of(
                        new AlertBrief(1L, 4L, "TEMPERATURE_ABNORMAL", "CRITICAL", Instant.now(), null),
                        new AlertBrief(2L, 8L, "TEMPERATURE_ABNORMAL", "WARNING", Instant.now(), null),
                        new AlertBrief(3L, 16L, "ESTRUS", "WARNING", Instant.now(), null)));

        HealthOverviewResponse res = service.getOverview(1L);

        // ELEVATED counts as fever-abnormal (ticket-consistent with the bridge)
        assertThat(res.sceneSummary().fever().abnormalCount()).isEqualTo(2);
        assertThat(res.sceneSummary().fever().activeAlertCount()).isEqualTo(2);
        // estrus high from CURRENT snapshot (#16 = 82), not history
        assertThat(res.sceneSummary().estrus().highScoreCount()).isEqualTo(1);
        assertThat(res.sceneSummary().estrus().activeAlertCount()).isEqualTo(1);
    }
}
