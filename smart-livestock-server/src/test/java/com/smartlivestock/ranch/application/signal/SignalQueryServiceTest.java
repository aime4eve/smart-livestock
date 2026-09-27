package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.model.TempStatus;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.infrastructure.persistence.jpa.AnomalyScoreJpaRepository;
import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.ranch.application.signal.SignalDtos.LivestockSignal;
import com.smartlivestock.ranch.application.signal.SignalDtos.LivestockSignalResponse;
import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.IoTQueryPort;
import com.smartlivestock.ranch.domain.repository.FenceRepository;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import com.smartlivestock.ranch.infrastructure.persistence.LivestockLocationSnapshotJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.SpringDataAlertRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.AlertJpaEntity;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SignalQueryServiceTest {

    @Mock
    private SignalRevisionService revisionService;
    @Mock
    private LivestockRepository livestockRepository;
    @Mock
    private LivestockLocationSnapshotJpaRepository locationRepository;
    @Mock
    private HealthSnapshotRepository healthSnapshotRepository;
    @Mock
    private AnomalyScoreJpaRepository anomalyScoreRepository;
    @Mock
    private SpringDataAlertRepository alertRepository;
    @Mock
    private FenceRepository fenceRepository;
    @Mock
    private IoTQueryPort ioTQueryPort;
    @Mock
    private UserFarmAssignmentRepository userFarmAssignmentRepository;

    private SignalQueryService service;

    @BeforeEach
    void setUp() {
        service = new SignalQueryService(
                revisionService,
                livestockRepository,
                locationRepository,
                healthSnapshotRepository,
                anomalyScoreRepository,
                alertRepository,
                fenceRepository,
                ioTQueryPort,
                userFarmAssignmentRepository
        );
    }

    @Test
    void rejectsUserWithoutActiveFarmAssignment() {
        when(userFarmAssignmentRepository.existsByUserIdAndFarmIdAndStatus(9L, 1L, "ACTIVE"))
                .thenReturn(false);

        assertThatThrownBy(() -> service.getLivestockSignals(
                1L, List.of(14L), "0", 9L
        ))
                .isInstanceOf(ApiException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.AUTH_FORBIDDEN);
    }

    @Test
    void cursorZeroPerformsInitialFullSyncWithNestedMetrics() {
        mockAuthorizedUser();
        mockRevision(0L, 0L, 0L);
        mockOneLivestockWithAiTemperatureAlert();

        LivestockSignalResponse response = service.getLivestockSignals(
                1L, List.of(14L), "0", 9L
        );

        assertThat(response.changed()).isTrue();
        assertThat(response.items()).hasSize(1);
        LivestockSignal signal = response.items().get(0);
        assertThat(signal.health().metrics().rumenTemperature().value()).isEqualTo(39.4);
        assertThat(signal.ai().status()).isEqualTo("ALERT");
        assertThat(signal.alerts().unreadCount()).isEqualTo(1);
    }

    @Test
    void unchangedCursorDoesNotBuildMapPayload() {
        mockAuthorizedUser();
        FarmSignalRevision revision = mockRevision(5L, 6L, 7L);
        when(revisionService.validateMapCursor(revision, "5:6:7"))
                .thenReturn(new SignalRevisionService.MapCursor(5L, 6L, 7L));

        var response = service.getMapSignals(1L, "5:6:7", true, 9L);

        assertThat(response.changed()).isFalse();
        assertThat(response.cursor()).isEqualTo("5:6:7");
        assertThat(response.fences()).isEmpty();
        assertThat(response.livestockSignals()).isEmpty();
        assertThat(response.positionUpdates()).isEmpty();
        verify(livestockRepository, never()).findByFarmId(1L);
    }

    @Test
    void aheadCursorUsesDedicatedErrorCode() {
        mockAuthorizedUser();
        mockRevision(2L, 2L, 2L);
        org.mockito.Mockito.doThrow(new SignalCursorInvalidException("cursor ahead"))
                .when(revisionService).validateListCursor(revisionService.ensureFarm(1L), 3L);
        assertThatThrownBy(() -> service.getLivestockSignals(
                1L, List.of(14L), "3", 9L
        ))
                .isInstanceOf(ApiException.class)
                .hasFieldOrPropertyWithValue("code", ErrorCode.SIGNAL_CURSOR_INVALID);
    }

    private void mockAuthorizedUser() {
        when(userFarmAssignmentRepository.existsByUserIdAndFarmIdAndStatus(9L, 1L, "ACTIVE"))
                .thenReturn(true);
    }

    private FarmSignalRevision mockRevision(long status, long position, long geometry) {
        FarmSignalRevision revision = new FarmSignalRevision(
                1L, status, position, geometry, Instant.now()
        );
        when(revisionService.ensureFarm(1L)).thenReturn(revision);
        return revision;
    }

    private void mockOneLivestockWithAiTemperatureAlert() {
        Livestock livestock = new Livestock();
        livestock.setId(14L);
        livestock.setFarmId(1L);
        livestock.setLivestockCode("HKT14");
        when(livestockRepository.findByFarmId(1L)).thenReturn(List.of(livestock));

        AlertJpaEntity alert = org.mockito.Mockito.mock(AlertJpaEntity.class);
        when(alert.getFarmId()).thenReturn(1L);
        when(alert.getLivestockId()).thenReturn(14L);
        when(alert.getFenceId()).thenReturn(null);
        when(alert.getDeviceId()).thenReturn(null);
        when(alert.getType()).thenReturn(com.smartlivestock.ranch.domain.model.AlertType.TEMPERATURE_ABNORMAL.name());
        when(alert.getSeverity()).thenReturn(com.smartlivestock.ranch.domain.model.Severity.CRITICAL.name());
        when(alert.getMessage()).thenReturn("AI temperature anomaly");
        when(alert.getId()).thenReturn(31L);
        when(alert.getSource()).thenReturn("AI");
        when(alertRepository.findByFarmIdAndStatus(1L, "ACTIVE")).thenReturn(List.of(alert));
        when(alertRepository.countActiveUnreadByLivestock(1L, 9L)).thenReturn(List.of(
                new SpringDataAlertRepository.LivestockUnreadCountProjection() {
                    @Override public Long getLivestockId() { return 14L; }
                    @Override public long getCnt() { return 1L; }
                }
        ));

        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(14L);
        snapshot.setFarmId(1L);
        snapshot.setCurrentTemp(new BigDecimal("39.4"));
        snapshot.setTempStatus(TempStatus.CRITICAL);
        snapshot.setCurrentTempRecordedAt(Instant.now());
        snapshot.setCurrentTempSource("AGENTIC_PLATFORM");
        snapshot.setCurrentMotility(new BigDecimal("2.1"));
        snapshot.setMotilityStatus(com.smartlivestock.health.domain.model.MotilityStatus.NORMAL);
        snapshot.setCurrentMotilityRecordedAt(Instant.now());
        snapshot.setCurrentMotilitySource("AGENTIC_PLATFORM");
        snapshot.setAiAnomalyScore(new BigDecimal("0.820"));
        snapshot.setAiAnomalyType("circadian_disruption");
        snapshot.setAiAssessedAt(Instant.now());
        when(healthSnapshotRepository.findByFarmId(1L)).thenReturn(List.of(snapshot));

        when(fenceRepository.findByFarmId(1L)).thenReturn(List.of());
        when(ioTQueryPort.findActiveDevicesByLivestockIds(any())).thenReturn(Map.of());
    }
}
