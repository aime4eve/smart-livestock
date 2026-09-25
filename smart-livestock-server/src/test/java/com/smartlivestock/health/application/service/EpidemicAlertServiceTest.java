package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EpidemicAlertServiceTest {

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;

    private EpidemicAlertService service;

    @BeforeEach
    void setUp() {
        service = new EpidemicAlertService(snapshotRepo, ranchQueryPort, ranchCommandPort);
        ReflectionTestUtils.setField(service, "enabled", true);
    }

    private AlertBrief ticket(long id, long livestockId, String type, Instant created) {
        return new AlertBrief(id, livestockId, type, "WARNING", created, null);
    }

    @Test
    void opensFarmWarningAboveTenPercent_andDeduplicates() {
        // 10 livestock, 2 with source tickets in window → 20% ≥ 10%
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(
                List.of(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L).stream()
                        .map(id -> new LivestockInfo(id, 1L, "SL-" + id, "F", "B")).toList());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, EpidemicAlertService.SOURCE_TYPES))
                .thenReturn(List.of(ticket(1L, 4L, "TEMPERATURE_ABNORMAL", Instant.now())));
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of(ticket(2L, 8L, "DIGESTIVE_ABNORMAL", Instant.now().minusSeconds(3600))));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.EPIDEMIC_TYPES))
                .thenReturn(List.of());

        double rate = service.evaluate(1L);
        assertThat(rate).isEqualTo(0.2);

        ArgumentCaptor<AlertInfo> captor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort).createAlert(captor.capture());
        assertThat(captor.getValue().alertType()).isEqualTo("EPIDEMIC");
        assertThat(captor.getValue().livestockId()).isNull();      // farm-level
        assertThat(captor.getValue().messageKey()).isEqualTo("alert.health.epidemic");
    }

    @Test
    void doesNotDuplicateWhenFarmWarningAlreadyActive() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(
                List.of(1L, 2L, 3L, 4L, 5L).stream()
                        .map(id -> new LivestockInfo(id, 1L, "SL-" + id, "F", "B")).toList());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, EpidemicAlertService.SOURCE_TYPES))
                .thenReturn(List.of(ticket(1L, 4L, "TEMPERATURE_ABNORMAL", Instant.now())));
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.EPIDEMIC_TYPES))
                .thenReturn(List.of(new AlertBrief(9L, null, "EPIDEMIC", "CRITICAL", Instant.now(), null)));

        service.evaluate(1L);
        verify(ranchCommandPort, never()).createAlert(any());
    }

    @Test
    void resolvesBelowFivePercent() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(
                List.of(1L, 2L, 3L, 4L, 5L).stream()
                        .map(id -> new LivestockInfo(id, 1L, "SL-" + id, "F", "B")).toList());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, EpidemicAlertService.SOURCE_TYPES))
                .thenReturn(List.of());  // 0% < 5%
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.EPIDEMIC_TYPES))
                .thenReturn(List.of(new AlertBrief(9L, null, "EPIDEMIC", "CRITICAL", Instant.now(), null)));

        service.evaluate(1L);
        verify(ranchCommandPort).resolveFarmAlertsByType(1L, "EPIDEMIC");
    }

    @Test
    void hysteresisBand_keepsWarningBetweenFiveAndTenPercent() {
        // 5 livestock, 1 source ticket → 20%? no: use 10 → 1 = 10% band check separately.
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(
                List.of(1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L).stream()
                        .map(id -> new LivestockInfo(id, 1L, "SL-" + id, "F", "B")).toList());
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, EpidemicAlertService.SOURCE_TYPES))
                .thenReturn(List.of(ticket(1L, 4L, "TEMPERATURE_ABNORMAL", Instant.now())));
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of());
        // active farm warning exists; rate = 10% → neither open nor resolve
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.EPIDEMIC_TYPES))
                .thenReturn(List.of(new AlertBrief(9L, null, "EPIDEMIC", "CRITICAL", Instant.now(), null)));

        double rate = service.evaluate(1L);
        assertThat(rate).isEqualTo(0.10);
        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveFarmAlertsByType(any(), any());
    }

    @Test
    void disabledSkipsScheduledRun() {
        ReflectionTestUtils.setField(service, "enabled", false);
        service.checkAllFarms();
        verify(ranchQueryPort, never()).findAllByFarmId(any());
    }
}
