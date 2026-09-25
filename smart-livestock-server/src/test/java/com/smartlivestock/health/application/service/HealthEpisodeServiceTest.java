package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.EpisodeBoard;
import com.smartlivestock.health.application.dto.HealthDtos.EpisodeRow;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HealthEpisodeServiceTest {

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private TemperatureLogRepository temperatureLogRepo;

    private HealthEpisodeService service;

    @BeforeEach
    void setUp() {
        service = new HealthEpisodeService(snapshotRepo, ranchQueryPort, temperatureLogRepo);
        lenient().when(ranchQueryPort.findReadAlertIds(any(), anyCollection())).thenReturn(Set.of());
    }

    private LivestockInfo livestock(long id) {
        return new LivestockInfo(id, 1L, "SL-" + id, "F", "SIMMENTAL");
    }

    private HealthSnapshot snapshot(long id, TempStatus temp, MotilityStatus motility, Integer estrus) {
        HealthSnapshot s = new HealthSnapshot();
        s.setLivestockId(id);
        s.setFarmId(1L);
        s.setTempStatus(temp);
        s.setMotilityStatus(motility);
        s.setEstrusScore(estrus);
        s.setCurrentTemp(BigDecimal.valueOf(41.2));
        s.setBaselineTemp(BigDecimal.valueOf(38.5));
        return s;
    }

    private AlertBrief alert(long id, long livestockId, String type, String severity, Instant created) {
        return new AlertBrief(id, livestockId, type, severity, created, null);
    }

    @Test
    void feverBoard_groupsAndReconciles() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(
                livestock(4), livestock(8), livestock(16), livestock(20)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(4L, TempStatus.CRITICAL, MotilityStatus.NORMAL, null),
                snapshot(8L, TempStatus.ELEVATED, MotilityStatus.NORMAL, null),
                snapshot(16L, TempStatus.NORMAL, MotilityStatus.NORMAL, null),
                snapshot(20L, TempStatus.NORMAL, MotilityStatus.NORMAL, null)));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.FEVER_TYPES))
                .thenReturn(List.of(
                        alert(100L, 4L, "TEMPERATURE_ABNORMAL", "CRITICAL", Instant.now().minusSeconds(7200)),
                        alert(101L, 8L, "TEMPERATURE_ABNORMAL", "WARNING", Instant.now().minusSeconds(3600))));
        // recovered-today lookup
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of(alert(90L, 16L, "TEMPERATURE_ABNORMAL", "WARNING",
                        Instant.now().minusSeconds(86400))));

        EpisodeBoard board = service.board(1L, "fever", 9L);

        assertThat(board.totalLivestock()).isEqualTo(4);
        assertThat(board.abnormal()).hasSize(2);      // CRITICAL + ELEVATED (ticket-consistent)
        assertThat(board.activeAlertCount()).isEqualTo(2);
        assertThat(board.reconciled()).isTrue();
        assertThat(board.recoveredToday()).extracting(EpisodeRow::livestockId)
                .containsExactly(16L);                // resolved today AND currently normal
        assertThat(board.normal()).extracting(EpisodeRow::livestockId).containsExactly(20L);

        EpisodeRow row = board.abnormal().get(0);
        assertThat(row.livestockId()).isEqualTo(4L);
        assertThat(row.statusLevel()).isEqualTo("critical");
        assertThat(row.durationHours()).isBetween(1.9, 2.1);
        assertThat(row.alertSeverity()).isEqualTo("CRITICAL");
        assertThat(row.unread()).isTrue();            // no read rows for user 9
        assertThat(row.aiBand()).isEqualTo("calm");   // no AI score on snapshot
    }

    @Test
    void estrusBoard_highScoreIsAbnormal() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(livestock(11), livestock(12)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(11L, TempStatus.NORMAL, MotilityStatus.NORMAL, 78),
                snapshot(12L, TempStatus.NORMAL, MotilityStatus.NORMAL, 40)));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.ESTRUS_TYPES))
                .thenReturn(List.of(alert(200L, 11L, "ESTRUS", "WARNING", Instant.now())));
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of());

        EpisodeBoard board = service.board(1L, "estrus", null);

        assertThat(board.abnormal()).extracting(EpisodeRow::livestockId).containsExactly(11L);
        assertThat(board.reconciled()).isTrue();
    }

    @Test
    void feverTrendUpFromRecentReadings() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(livestock(4)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(4L, TempStatus.FEVER, MotilityStatus.NORMAL, null)));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.FEVER_TYPES))
                .thenReturn(List.of(alert(100L, 4L, "TEMPERATURE_ABNORMAL", "CRITICAL", Instant.now())));
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of());
        when(temperatureLogRepo.findByLivestockIdAndTimeRange(eq(4L), any(), any()))
                .thenReturn(List.of(
                        tempLog(38.6), tempLog(38.8), tempLog(40.9), tempLog(41.2)));

        EpisodeBoard board = service.board(1L, "fever", null);
        assertThat(board.abnormal().get(0).trend()).isEqualTo("up");
    }

    private com.smartlivestock.health.domain.model.TemperatureLog tempLog(double v) {
        com.smartlivestock.health.domain.model.TemperatureLog log =
                new com.smartlivestock.health.domain.model.TemperatureLog();
        log.setTemperature(BigDecimal.valueOf(v));
        log.setRecordedAt(Instant.now());
        return log;
    }

    @Test
    void aiBandMappedOnRows() {
        when(ranchQueryPort.findAllByFarmId(1L)).thenReturn(List.of(livestock(4)));
        HealthSnapshot snap = snapshot(4L, TempStatus.FEVER, MotilityStatus.NORMAL, null);
        snap.setAiAnomalyScore(BigDecimal.valueOf(0.75));
        snap.setAiAnomalyType("abrupt_change");
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(snap));
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, HealthEpisodeService.FEVER_TYPES))
                .thenReturn(List.of());
        when(ranchQueryPort.findResolvedAlertsByFarmIdAndTypesSince(eq(1L), anyCollection(), any()))
                .thenReturn(List.of());

        EpisodeRow row = service.board(1L, "fever", null).abnormal().get(0);
        assertThat(row.aiBand()).isEqualTo("alarm");
        assertThat(row.aiFindingCode()).isEqualTo("temp_spike");
    }
}
