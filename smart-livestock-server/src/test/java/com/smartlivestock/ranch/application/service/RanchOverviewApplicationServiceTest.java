package com.smartlivestock.ranch.application.service;

import com.smartlivestock.ranch.application.RanchOverviewApplicationService;
import com.smartlivestock.ranch.application.dto.RanchOverviewDto.RanchOverviewResponse;
import com.smartlivestock.ranch.domain.model.*;
import com.smartlivestock.ranch.domain.port.HealthQueryPort;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.LivestockHealthState;
import com.smartlivestock.ranch.domain.port.HealthQueryPort.HealthOverview;
import com.smartlivestock.ranch.domain.port.dto.FarmInfo;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RanchOverviewApplicationServiceTest {

    @Mock private FenceRepository fenceRepository;
    @Mock private LivestockRepository livestockRepository;
    @Mock private AlertRepository alertRepository;
    @Mock private HealthQueryPort healthQueryPort;
    @Mock private IoTQueryPort ioTQueryPort;
    @Mock private IdentityQueryPort identityQueryPort;

    @InjectMocks
    private RanchOverviewApplicationService service;

    private void setupDefaultMocks() {
        when(identityQueryPort.findFarmById(1L))
                .thenReturn(Optional.of(new FarmInfo(1L, 1L, "Test", null, null)));
        when(ioTQueryPort.getDeviceOnlineRate(1L)).thenReturn(0.85);
    }

    private RanchOverviewResponse getOverviewForEmptyFarm() {
        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0));
        return service.getOverview(1L);
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
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0));

        RanchOverviewResponse response = service.getOverview(1L);

        assertThat(response.fences()).hasSize(1);
        assertThat(response.fences().get(0).name()).isEqualTo("东区");
    }

    @Test
    @DisplayName("should return livestock markers with WARNING health status for FEVER")
    void livestockWithWarningHealth() {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        l1.updatePosition(new BigDecimal("28.246"), new BigDecimal("112.852"));

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "FEVER", "NORMAL", 0)
        ));
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(1, 0.0, 0, 0, 1, 0, 0, 0, 0, 0.0));

        RanchOverviewResponse response = service.getOverview(1L);

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
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "CRITICAL", "NORMAL", 0)
        ));
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(1, 0.0, 0, 1, 1, 1, 0, 0, 0, 1.0));

        RanchOverviewResponse response = service.getOverview(1L);

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
        archived.acknowledge(99L);
        archived.handle(99L);
        archived.archive(99L);

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(alertRepository.findByFarmId(1L)).thenReturn(List.of(pending, archived));
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(0, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0));

        RanchOverviewResponse response = service.getOverview(1L);

        assertThat(response.alerts()).hasSize(1);
        assertThat(response.alerts().get(0).status()).isEqualTo("PENDING");
    }

    @Test
    @DisplayName("should skip livestock without GPS position")
    void skipLivestockWithoutGps() {
        setupDefaultMocks();
        Livestock l1 = new Livestock(1L, "SL-001", "Holstein", "F", null, null);
        l1.setId(1L);
        // No position set

        when(fenceRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(l1));
        when(alertRepository.findByFarmId(1L)).thenReturn(Collections.emptyList());
        when(healthQueryPort.findHealthByFarmId(1L)).thenReturn(List.of(
                new LivestockHealthState(1L, "NORMAL", "NORMAL", 0)
        ));
        when(healthQueryPort.getHealthOverview(1L)).thenReturn(
                new HealthOverview(1, 1.0, 0, 0, 0, 0, 0, 0, 0, 0.0));

        RanchOverviewResponse response = service.getOverview(1L);

        assertThat(response.livestockMarkers()).isEmpty();
    }
}
