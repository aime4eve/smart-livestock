package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.MotilityStatus;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.RanchQueryPort.AlertBrief;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StaleHealthAlertReconcilerTest {

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;

    private StaleHealthAlertReconciler reconciler;

    @BeforeEach
    void setUp() {
        reconciler = new StaleHealthAlertReconciler(snapshotRepo, ranchQueryPort, ranchCommandPort,
                new CalvingPredictionProperties());
        ReflectionTestUtils.setField(reconciler, "enabled", true);
    }

    private HealthSnapshot snapshot(long id, TempStatus temp, MotilityStatus motility, Integer estrus) {
        HealthSnapshot s = new HealthSnapshot();
        s.setLivestockId(id);
        s.setFarmId(1L);
        s.setTempStatus(temp);
        s.setMotilityStatus(motility);
        s.setEstrusScore(estrus);
        return s;
    }

    @Test
    void resolvesTicketWhenStateRecovered() {
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, StaleHealthAlertReconciler.HEALTH_TYPES))
                .thenReturn(List.of(
                        new AlertBrief(1L, 4L, "TEMPERATURE_ABNORMAL", "CRITICAL", Instant.now(), null),
                        new AlertBrief(2L, 5L, "ESTRUS", "WARNING", Instant.now(), null)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(4L, TempStatus.NORMAL, MotilityStatus.NORMAL, null),   // recovered → resolve
                snapshot(5L, TempStatus.NORMAL, MotilityStatus.NORMAL, 78)));   // still high → keep

        int resolved = reconciler.reconcileFarm(1L);

        assertThat(resolved).isEqualTo(1);
        verify(ranchCommandPort).resolveAlert(4L, "TEMPERATURE_ABNORMAL");
        verify(ranchCommandPort, never()).resolveAlert(5L, "ESTRUS");
    }

    @Test
    void keepsTicketWhenStillAbnormalAndSkipsMissingSnapshot() {
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, StaleHealthAlertReconciler.HEALTH_TYPES))
                .thenReturn(List.of(
                        new AlertBrief(1L, 4L, "DIGESTIVE_ABNORMAL", "WARNING", Instant.now(), null),
                        new AlertBrief(2L, 99L, "TEMPERATURE_ABNORMAL", "WARNING", Instant.now(), null)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(4L, TempStatus.NORMAL, MotilityStatus.ABNORMAL, null))); // still abnormal

        int resolved = reconciler.reconcileFarm(1L);

        assertThat(resolved).isZero();
        verify(ranchCommandPort, never()).resolveAlert(org.mockito.ArgumentMatchers.anyLong(),
                org.mockito.ArgumentMatchers.anyString());
    }

    @Test
    void estrusTicketResolvedWhenScoreDropped() {
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, StaleHealthAlertReconciler.HEALTH_TYPES))
                .thenReturn(List.of(new AlertBrief(1L, 5L, "ESTRUS", "WARNING", Instant.now(), null)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(5L, TempStatus.NORMAL, MotilityStatus.NORMAL, 62)));

        assertThat(reconciler.reconcileFarm(1L)).isEqualTo(1);
        verify(ranchCommandPort).resolveAlert(5L, "ESTRUS");
    }

    private HealthSnapshot calvingSnapshot(long id, Integer calvingRiskScore) {
        HealthSnapshot s = snapshot(id, TempStatus.NORMAL, MotilityStatus.NORMAL, 0);
        s.setCalvingRiskScore(calvingRiskScore);
        return s;
    }

    @Test
    void calvingTicket_resolvedWhenScoreClearedOrBelowRelease_keptInHoldBand() {
        when(ranchQueryPort.findActiveAlertsByFarmIdAndTypes(1L, StaleHealthAlertReconciler.HEALTH_TYPES))
                .thenReturn(List.of(
                        new AlertBrief(1L, 6L, "CALVING_WARNING", "WARNING", Instant.now(), null),
                        new AlertBrief(2L, 7L, "CALVING_WARNING", "WARNING", Instant.now(), null),
                        new AlertBrief(3L, 8L, "CALVING_WARNING", "WARNING", Instant.now(), null),
                        new AlertBrief(4L, 9L, "CALVING_WARNING", "WARNING", Instant.now(), null)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                calvingSnapshot(6L, null),   // released / never scored → stale
                calvingSnapshot(7L, 54),     // below release 55 → stale
                calvingSnapshot(8L, 55),     // hold band → keep
                calvingSnapshot(9L, 82)));   // still alarming → keep

        assertThat(reconciler.reconcileFarm(1L)).isEqualTo(2);
        verify(ranchCommandPort).resolveAlert(6L, "CALVING_WARNING");
        verify(ranchCommandPort).resolveAlert(7L, "CALVING_WARNING");
        verify(ranchCommandPort, never()).resolveAlert(8L, "CALVING_WARNING");
        verify(ranchCommandPort, never()).resolveAlert(9L, "CALVING_WARNING");
    }

    @Test
    void healthTypes_includeCalvingWarning() {
        assertThat(StaleHealthAlertReconciler.HEALTH_TYPES).contains("CALVING_WARNING");
    }
}
