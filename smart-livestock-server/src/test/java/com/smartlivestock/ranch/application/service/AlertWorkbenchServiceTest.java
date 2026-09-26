package com.smartlivestock.ranch.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.EpisodeBoard;
import com.smartlivestock.health.application.dto.HealthDtos.EpisodeRow;
import com.smartlivestock.health.application.service.HealthEpisodeService;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.WorkbenchItem;
import com.smartlivestock.ranch.application.dto.AlertWorkbenchDto.WorkbenchResponse;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Fence;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertReadStatusRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AlertWorkbenchServiceTest {

    @Mock private AlertRepository alertRepository;
    @Mock private LivestockRepository livestockRepository;
    @Mock private FenceRepository fenceRepository;
    @Mock private SpringDataAlertReadStatusRepository readStatusRepository;
    @Mock private IoTQueryPort ioTQueryPort;
    @Mock private HealthEpisodeService healthEpisodeService;

    private AlertWorkbenchService service() {
        return new AlertWorkbenchService(alertRepository, livestockRepository, fenceRepository,
                readStatusRepository, ioTQueryPort, new AlertMessageLocalizer(null, null) {
            @Override
            public String localize(com.smartlivestock.ranch.domain.model.Alert alert) {
                return alert.getMessage();
            }
        }, healthEpisodeService);
    }

    private Alert alert(Long id, AlertType type, Severity severity, String status,
                        Long livestockId, Long fenceId, Long deviceId) {
        Alert alert = new Alert(1L, livestockId, fenceId, deviceId, type, severity, "seed message " + id);
        alert.setId(id);
        alert.setStatus(AlertStatus.valueOf(status));
        alert.setCreatedAt(Instant.parse("2026-09-25T01:00:00Z"));
        return alert;
    }

    private Livestock livestock(Long id) {
        Livestock livestock = new Livestock();
        livestock.setId(id);
        livestock.setLivestockCode("SL-" + id);
        livestock.setBreed("Angus");
        return livestock;
    }

    private Fence fence(Long id) {
        Fence fence = new Fence();
        fence.setId(id);
        fence.setName("North");
        return fence;
    }

    private EpisodeBoard emptyBoard() {
        return new EpisodeBoard("fever", 2, 0, 0, true, 0,
                List.of(), List.of(), List.of());
    }

    private EpisodeRow watchRow(Long livestockId) {
        return new EpisodeRow(livestockId, "SL-" + livestockId, "normal", 40.0, 38.5,
                3.0, "up", 0.45, "watch", "temp_spike",
                Instant.parse("2026-09-25T01:00:00Z"), 0, null, false);
    }

    @Test
    void criticalFenceBreachIsImmediateAndFenceAnchored() {
        Alert alert = alert(10L, AlertType.FENCE_BREACH, Severity.CRITICAL,
                "ACTIVE", 7L, 3L, null);
        when(alertRepository.findByFarmId(1L)).thenReturn(List.of(alert));
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(livestock(7L)));
        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of(fence(3L)));
        when(ioTQueryPort.findDeviceCodesByIds(any())).thenReturn(java.util.Map.of());
        when(healthEpisodeService.board(anyLong(), any(), any())).thenReturn(emptyBoard());

        WorkbenchResponse response = service().workbench(1L, 9L, "all",
                List.of("all"), null, 1, 50);

        assertThat(response.total()).isEqualTo(1);
        assertThat(response.items().get(0).bucket()).isEqualTo("immediate");
        assertThat(response.items().get(0).asset().kind()).isEqualTo("fence");
        assertThat(response.items().get(0).asset().name()).isEqualTo("North");
        assertThat(response.summary().buckets().stream()
                .filter(bucket -> bucket.key().equals("immediate"))
                .findFirst().orElseThrow().total()).isEqualTo(1);
    }

    @Test
    void lowBatteryIsFieldAndDeviceAnchored() {
        Alert alert = alert(11L, AlertType.DEVICE_LOW_BATTERY, Severity.WARNING,
                "ACTIVE", 7L, null, 21L);
        when(alertRepository.findByFarmId(1L)).thenReturn(List.of(alert));
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of());
        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of());
        when(ioTQueryPort.findDeviceCodesByIds(any())).thenReturn(java.util.Map.of(21L, "CAP-21"));
        when(healthEpisodeService.board(anyLong(), any(), any())).thenReturn(emptyBoard());

        WorkbenchResponse response = service().workbench(1L, 9L, "all",
                List.of("device"), null, 1, 50);

        assertThat(response.total()).isEqualTo(1);
        assertThat(response.items().get(0).bucket()).isEqualTo("field");
        assertThat(response.items().get(0).asset().kind()).isEqualTo("device");
        assertThat(response.items().get(0).asset().name()).isEqualTo("CAP-21");
    }

    @Test
    void aiWatchWithoutTicketIsObserve() {
        EpisodeRow row = watchRow(7L);
        EpisodeBoard board = new EpisodeBoard("fever", 2, 0, 0, true, 0,
                List.of(), List.of(), List.of(row));
        when(alertRepository.findByFarmId(1L)).thenReturn(List.of());
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(livestock(7L)));
        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of());
        when(ioTQueryPort.findDeviceCodesByIds(any())).thenReturn(java.util.Map.of());
        when(healthEpisodeService.board(anyLong(), any(), any())).thenReturn(board);

        WorkbenchResponse response = service().workbench(1L, 9L, "all",
                List.of("livestock"), null, 1, 50);

        assertThat(response.total()).isEqualTo(1);
        WorkbenchItem item = response.items().get(0);
        assertThat(item.bucket()).isEqualTo("observe");
        assertThat(item.reasons()).isEmpty();
        assertThat(item.ai().band()).isEqualTo("watch");
    }
}
