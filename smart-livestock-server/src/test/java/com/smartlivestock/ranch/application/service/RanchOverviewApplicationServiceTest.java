package com.smartlivestock.ranch.application.service;

import com.smartlivestock.ranch.application.RanchOverviewApplicationService;
import com.smartlivestock.ranch.application.service.AlertMessageLocalizer;
import com.smartlivestock.ranch.application.dto.RanchOverviewDto.RanchOverviewResponse;
import com.smartlivestock.ranch.domain.model.*;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.LockedTilePolicyPort;
import com.smartlivestock.ranch.domain.port.SceneGatePort;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.LivestockHealthState;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.HealthOverview;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.FenceZoneRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.domain.service.FenceLivestockCounter;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RanchOverviewApplicationServiceTest {

    @Mock private FenceRepository fenceRepository;
    @Mock private LivestockRepository livestockRepository;
    @Mock private AlertRepository alertRepository;
    @Mock private HealthQueryPort healthQueryPort;
    @Mock private IoTQueryPort ioTQueryPort;
    @Mock private IdentityQueryPort identityQueryPort;
    @Mock private SpringDataAlertReadStatusRepository readStatusRepository;
    @Mock private FenceZoneRepository fenceZoneRepository;
    @Mock private AlertMessageLocalizer alertMessageLocalizer;
    @Mock private SceneGatePort sceneGatePort;
    @Mock private LockedTilePolicyPort lockedTilePolicyPort;

    private RanchOverviewApplicationService service;

    @BeforeEach
    void setUp() {
        // Real FenceLivestockCounter so fence counts exercise the shared
        // point-in-polygon logic instead of Mockito defaults.
        service = new RanchOverviewApplicationService(
                fenceRepository, livestockRepository, alertRepository, healthQueryPort,
                ioTQueryPort, identityQueryPort, readStatusRepository, fenceZoneRepository,
                new FenceLivestockCounter(), null, null, alertMessageLocalizer,
                sceneGatePort, lockedTilePolicyPort);
    }

    private void setupDefaultMocks() {
        when(identityQueryPort.findFarmById(1L))
                .thenReturn(Optional.of(new FarmInfo(1L, 1L, "Test", null, null)));
        when(ioTQueryPort.getDeviceOnlineRate(1L)).thenReturn(0.85);
        when(ioTQueryPort.findActiveDevicesByLivestockIds(org.mockito.ArgumentMatchers.anyList()))
                .thenAnswer(invocation -> {
                    List<Long> livestockIds = invocation.getArgument(0);
                    java.util.Map<Long, java.util.List<com.smartlivestock.ranch.domain.port.dto.DeviceBrief>> devices =
                            new java.util.HashMap<>();
                    for (Long livestockId : livestockIds) {
                        devices.put(livestockId, List.of(new com.smartlivestock.ranch.domain.port.dto.DeviceBrief(
                                livestockId + 100, "GPS-" + livestockId, null, "TRACKER")));
                    }
                    return devices;
                });
    }

    private RanchOverviewResponse getOverviewForEmptyFarm() {
        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0, 0));
        return service.getOverview(1L, 1L, 1L);
    }

    @Test
    @DisplayName("should return empty overview when farm has no data")
    void emptyFarm() {
        setupDefaultMocks();
        RanchOverviewResponse response = getOverviewForEmptyFarm();

        assertThat(response.fences()).isEmpty();
        assertThat(response.livestockMarkers()).isEmpty();
        assertThat(response.alerts()).isEmpty();
        assertThat(response.pendingTasks()).isEmpty();
        assertThat(response.overallStats().totalLivestock()).isEqualTo(0);
    }

    @Test
    @DisplayName("should return fences from repository")
    void fencesLoaded() {
        setupDefaultMocks();
        Fence fence = new Fence(1L, "东区", List.of(
                new GpsCoordinate("28.246", "112.852"),
                new GpsCoordinate("28.247", "112.853"),
                new GpsCoordinate("28.245", "112.854")
        ), "#FF4C9A5F");
        fence.setId(10L);

        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of(fence));
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0, 0));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.fences()).hasSize(1);
        assertThat(response.fences().get(0).name()).isEqualTo("东区");
    }

    @Test
    @DisplayName("should echo generationMetadata on FenceData when present, null otherwise")
    void fenceGenerationMetadataEcho() {
        setupDefaultMocks();
        Fence withMeta = new Fence(1L, "轨迹围栏", List.of(
                new GpsCoordinate("28.246", "112.852"),
                new GpsCoordinate("28.247", "112.853"),
                new GpsCoordinate("28.245", "112.854")
        ), "#FF4C9A5F");
        withMeta.setId(10L);
        withMeta.setGenerationMetadata(
                "{\"method\":\"DEVICE_TRACK\",\"deviceIds\":[101,102],\"usedPoints\":7412}");
        Fence withoutMeta = new Fence(1L, "手绘围栏", List.of(
                new GpsCoordinate("28.256", "112.862"),
                new GpsCoordinate("28.257", "112.863"),
                new GpsCoordinate("28.255", "112.864")
        ), "#FF4C9A5F");
        withoutMeta.setId(11L);

        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of(withMeta, withoutMeta));
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0, 0));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.fences()).hasSize(2);
        var meta = response.fences().get(0).generationMetadata();
        assertThat(meta).isNotNull();
        assertThat(meta.get("method")).isEqualTo("DEVICE_TRACK");
        assertThat(meta.get("deviceIds")).isEqualTo(List.of(101, 102));
        assertThat(meta.get("usedPoints")).isEqualTo(7412);
        assertThat(response.fences().get(1).generationMetadata()).isNull();
    }

    @Test
    @DisplayName("should count livestock whose current GPS position is inside each fence")
    void fenceLivestockCount() {
        setupDefaultMocks();
        Fence activeFence = new Fence(1L, "东区", List.of(
                new GpsCoordinate("28.0", "112.0"),
                new GpsCoordinate("28.1", "112.0"),
                new GpsCoordinate("28.1", "112.1"),
                new GpsCoordinate("28.0", "112.1")
        ), "#4CAF50");
        activeFence.setId(10L);

        Fence inactiveFence = new Fence(1L, "西区", List.of(
                new GpsCoordinate("29.0", "113.0"),
                new GpsCoordinate("29.1", "113.0"),
                new GpsCoordinate("29.1", "113.1"),
                new GpsCoordinate("29.0", "113.1")
        ), "#FF5722");
        inactiveFence.setId(11L);
        inactiveFence.disable();

        Livestock inside = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        inside.setId(1L);
        inside.updatePosition(new BigDecimal("28.05"), new BigDecimal("112.05"));

        Livestock outside = new Livestock(1L, "SL-002", "Holstein", "F", null, null);
        outside.setId(2L);
        outside.updatePosition(new BigDecimal("28.2"), new BigDecimal("112.05"));

        Livestock withoutGps = new Livestock(1L, "SL-003", "Holstein", "F", null, null);
        withoutGps.setId(3L);

        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of(activeFence, inactiveFence));
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(inside, outside, withoutGps));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.fences().get(0).livestockCount()).isEqualTo(1);
        assertThat(response.fences().get(1).livestockCount()).isZero();
        // Location breakdown reconciles with totalLivestock:
        // 3 = 1 inside + 1 outside + 1 without GPS fix
        assertThat(response.overallStats().totalLivestock()).isEqualTo(3);
        assertThat(response.overallStats().noGpsCount()).isEqualTo(1);
        assertThat(response.overallStats().outsideFenceCount()).isEqualTo(1);
        assertThat(response.overallStats().inFenceRate()).isEqualTo(0.5);
    }

    @Test
    @DisplayName("should return livestock markers with WARNING health status for FEVER")
    void livestockWithWarningHealth() {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        l1.updatePosition(new BigDecimal("28.246"), new BigDecimal("112.852"));

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "FEVER", "NORMAL", 0, null, null, "NORMAL", null)
        ));
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(1, 0.0, 0, 0, 1, 0, 0, 0, 0, 0.0, 0, 0));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.livestockMarkers()).hasSize(1);
        assertThat(response.livestockMarkers().get(0).healthStatus()).isEqualTo("WARNING");
        assertThat(response.livestockMarkers().get(0).primaryAlert()).isEqualTo("FEVER");
    }

    @Test
    @DisplayName("should derive CRITICAL status for CRITICAL temp")
    void criticalHealthStatus() {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        l1.updatePosition(new BigDecimal("28.246"), new BigDecimal("112.852"));

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "CRITICAL", "NORMAL", 0, null, null, "NORMAL", null)
        ));
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(1, 0.0, 0, 1, 1, 1, 0, 0, 0, 1.0, 0, 0));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.livestockMarkers().get(0).healthStatus()).isEqualTo("CRITICAL");
        assertThat(response.pendingTasks()).hasSize(1);
        assertThat(response.pendingTasks().get(0).severity()).isEqualTo("CRITICAL");
    }

    @Test
    @DisplayName("should filter out archived alerts from response")
    void filterArchivedAlerts() {
        setupDefaultMocks();
        Alert pending = new Alert(1L, null, null, AlertType.FENCE_BREACH, Severity.CRITICAL, "test pending");
        pending.setId(1L);

        Alert archived = new Alert(1L, null, null, AlertType.FENCE_BREACH, Severity.INFO, "archived alert");
        archived.setId(2L);
        archived.autoResolve();

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(List.of(pending, archived));
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0, 0));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.alerts()).hasSize(1);
        assertThat(response.alerts().get(0).status()).isEqualTo("ACTIVE");
    }

    @Test
    @DisplayName("should skip livestock without GPS position")
    void skipLivestockWithoutGps() {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        // No position set

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "NORMAL", "NORMAL", 0, null, null, "NORMAL", null)
        ));
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(1, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0, 0));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.livestockMarkers()).isEmpty();
    }

    // ── Calving map linkage + pending task (NIX-381) ────────────

    /** One tracked livestock with a GPS fix, NORMAL on every other rule. */
    private RanchOverviewResponse overviewWithCalvingScore(Integer calvingRiskScore, List<Alert> alerts) {
        return overviewWithScores(0, calvingRiskScore, alerts);
    }

    /** Same fixture with an explicit estrus score, for sibling-precedence checks. */
    private RanchOverviewResponse overviewWithScores(int estrusScore, Integer calvingRiskScore, List<Alert> alerts) {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        l1.updatePosition(new BigDecimal("28.246"), new BigDecimal("112.852"));

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(alerts);
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "NORMAL", "NORMAL", estrusScore, null, null, "NORMAL", calvingRiskScore)
        ));
        return service.getOverview(1L, 1L, 1L);
    }

    @Test
    @DisplayName("calving risk at the alert threshold turns the marker WARNING with a calving task")
    void calvingRiskAtThreshold_markerWarning() {
        RanchOverviewResponse response = overviewWithCalvingScore(70, Collections.emptyList());

        assertThat(response.livestockMarkers()).hasSize(1);
        assertThat(response.livestockMarkers().get(0).healthStatus()).isEqualTo("WARNING");
        assertThat(response.livestockMarkers().get(0).primaryAlert()).isEqualTo("CALVING");
        assertThat(response.pendingTasks()).hasSize(1);
        var task = response.pendingTasks().get(0);
        assertThat(task.severity()).isEqualTo("WARNING");
        assertThat(task.title()).isEqualTo("SL-001 临产预警");
        assertThat(task.subtitle()).isEqualTo("临产风险 70");
        // No dedicated calving detail page yet.
        assertThat(task.routePath()).isEmpty();
    }

    @Test
    @DisplayName("null or below-threshold calving risk leaves the marker NORMAL")
    void calvingRiskNullOrBelowThreshold_markerNormal() {
        RanchOverviewResponse unscored = overviewWithCalvingScore(null, Collections.emptyList());
        assertThat(unscored.livestockMarkers().get(0).healthStatus()).isEqualTo("NORMAL");
        assertThat(unscored.livestockMarkers().get(0).primaryAlert()).isEmpty();
        assertThat(unscored.pendingTasks()).isEmpty();

        RanchOverviewResponse holdBand = overviewWithCalvingScore(60, Collections.emptyList());
        assertThat(holdBand.livestockMarkers().get(0).healthStatus()).isEqualTo("NORMAL");
        assertThat(holdBand.livestockMarkers().get(0).primaryAlert()).isEmpty();
        assertThat(holdBand.pendingTasks()).isEmpty();
    }

    @Test
    @DisplayName("estrus keeps precedence over a concurrent calving risk")
    void estrusAndCalving_estrusTakesPrecedence() {
        RanchOverviewResponse response = overviewWithScores(85, 90, Collections.emptyList());

        assertThat(response.livestockMarkers().get(0).healthStatus()).isEqualTo("WARNING");
        assertThat(response.livestockMarkers().get(0).primaryAlert()).isEqualTo("ESTRUS");
        assertThat(response.pendingTasks()).hasSize(1);
        var task = response.pendingTasks().get(0);
        assertThat(task.title()).isEqualTo("SL-001 发情高分");
        assertThat(task.subtitle()).isEqualTo("发情评分 85");
        assertThat(task.routePath()).isEqualTo("/twin/estrus/1");
    }

    @Test
    @DisplayName("an ACTIVE CALVING_WARNING ticket lights the health-ticket red dot")
    void calvingTicket_setsHealthTicketDot() {
        Alert calving = new Alert(1L, 1L, null, AlertType.CALVING_WARNING, Severity.WARNING, "calving");
        calving.setId(5L);

        RanchOverviewResponse response = overviewWithCalvingScore(75, List.of(calving));

        assertThat(response.livestockMarkers().get(0).hasHealthTicket()).isTrue();
        assertThat(response.livestockMarkers().get(0).healthStatus()).isEqualTo("WARNING");
    }

    // ── NIX-389: calving tile counts + three-state scene gating ──

    /**
     * Empty single-livestock overview with the given snapshot calving risk
     * score (no gates stubbed — every scene OPEN by default).
     */
    private RanchOverviewResponse overviewWithHealthState(Integer calvingRiskScore) {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        l1.updatePosition(new BigDecimal("28.246"), new BigDecimal("112.852"));
        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "NORMAL", "NORMAL", 0, null, null, "NORMAL", calvingRiskScore)
        ));
        return service.getOverview(1L, 1L, 1L);
    }

    @Test
    @DisplayName("calving tile counts: >=70 high risk, 50-69 watch, null/absent snapshot not counted")
    void calvingTileCount_bands() {
        setupDefaultMocks();
        Livestock high = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        high.setId(1L);
        Livestock watch = new Livestock(1L, "SL-002", "Holstein", "F", null, null);
        watch.setId(2L);
        Livestock unscored = new Livestock(1L, "SL-003", "Holstein", "F", null, null);
        unscored.setId(3L);
        Livestock noSnapshot = new Livestock(1L, "SL-004", "Holstein", "F", null, null);
        noSnapshot.setId(4L);

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(fenceZoneRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(high, watch, unscored, noSnapshot));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "NORMAL", "NORMAL", 0, null, null, "NORMAL", 70),
                new LivestockHealthState(2L, "NORMAL", "NORMAL", 0, null, null, "NORMAL", 60),
                new LivestockHealthState(3L, "NORMAL", "NORMAL", 0, null, null, "NORMAL", null)
        ));

        RanchOverviewResponse response = service.getOverview(1L, 1L, 1L);

        assertThat(response.sceneSummary().calving().highRiskCount()).isEqualTo(1);
        assertThat(response.sceneSummary().calving().watchCount()).isEqualTo(1);
    }

    @Test
    @DisplayName("calving tile watch band is inclusive at 50 and exclusive below 70")
    void calvingTileCount_bandEdges() {
        RanchOverviewResponse at50 = overviewWithHealthState(50);
        assertThat(at50.sceneSummary().calving().highRiskCount()).isZero();
        assertThat(at50.sceneSummary().calving().watchCount()).isEqualTo(1);

        RanchOverviewResponse at49 = overviewWithHealthState(49);
        assertThat(at49.sceneSummary().calving().highRiskCount()).isZero();
        assertThat(at49.sceneSummary().calving().watchCount()).isZero();
    }

    @Test
    @DisplayName("unlocked gate ships OPEN even when the platform policy would hide locked tiles")
    void gating_gateOpen_OPEN() {
        when(sceneGatePort.isLocked("temperature_monitor")).thenReturn(false);
        when(lockedTilePolicyPort.getLockedTilePolicy()).thenReturn("HIDE");

        RanchOverviewResponse response = overviewWithHealthState(null);

        assertThat(response.sceneSummary().gating().fever()).isEqualTo("OPEN");
    }

    @Test
    @DisplayName("locked gate + SHOW_LOCKED policy ships LOCKED")
    void gating_lockedGateShowLocked_LOCKED() {
        when(sceneGatePort.isLocked("calving_warning")).thenReturn(true);
        when(lockedTilePolicyPort.getLockedTilePolicy()).thenReturn("SHOW_LOCKED");

        RanchOverviewResponse response = overviewWithHealthState(null);

        assertThat(response.sceneSummary().gating().calving()).isEqualTo("LOCKED");
    }

    @Test
    @DisplayName("locked gate + HIDE policy ships HIDDEN")
    void gating_lockedGateHide_HIDDEN() {
        when(sceneGatePort.isLocked("calving_warning")).thenReturn(true);
        when(lockedTilePolicyPort.getLockedTilePolicy()).thenReturn("HIDE");

        RanchOverviewResponse response = overviewWithHealthState(null);

        assertThat(response.sceneSummary().gating().calving()).isEqualTo("HIDDEN");
    }

    @Test
    @DisplayName("all six tiles walk the gate keys to their own state field")
    void gating_allSixScenes_keyMapping() {
        // estrus + calving locked, everything else open; SHOW_LOCKED policy.
        when(lockedTilePolicyPort.getLockedTilePolicy()).thenReturn("SHOW_LOCKED");
        when(sceneGatePort.isLocked(org.mockito.ArgumentMatchers.anyString()))
                .thenAnswer(inv -> {
                    String key = inv.getArgument(0, String.class);
                    return "estrus_detect".equals(key) || "calving_warning".equals(key);
                });

        RanchOverviewResponse response = overviewWithHealthState(null);

        var gating = response.sceneSummary().gating();
        assertThat(gating.fever()).isEqualTo("OPEN");
        assertThat(gating.digestive()).isEqualTo("OPEN");
        assertThat(gating.estrus()).isEqualTo("LOCKED");
        assertThat(gating.epidemic()).isEqualTo("OPEN");
        assertThat(gating.ai()).isEqualTo("OPEN");
        assertThat(gating.calving()).isEqualTo("LOCKED");
    }
}
