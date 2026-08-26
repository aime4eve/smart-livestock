package com.smartlivestock.health.application.service;

import com.smartlivestock.health.domain.model.*;
import static org.mockito.ArgumentMatchers.any;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.*;
import com.smartlivestock.health.domain.service.*;
import com.smartlivestock.iot.domain.model.DeviceType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.quality.Strictness;
import org.mockito.junit.jupiter.MockitoSettings;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class HealthApplicationServiceTelemetryTest {

    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private TemperatureLogRepository tempLogRepo;
    @Mock private RumenMotilityLogRepository motilityLogRepo;
    @Mock private ActivityLogRepository activityLogRepo;
    @Mock private EstrusScoreRepository estrusScoreRepo;
    @Mock private ContactTraceRepository contactTraceRepo;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private HealthSubscriptionPort subscriptionPort;
    @Mock private FeverAnalysisService feverService;
    @Mock private DigestiveAnalysisService digestiveService;
    @Mock private EstrusAnalysisService estrusAnalysisService;
    @Mock private EpidemicAnalysisService epidemicService;
    @Mock private HealthAnomalyService healthAnomalyService;

    private HealthApplicationService service;

    @BeforeEach
    void setUp() {
        service = new HealthApplicationService(
                snapshotRepo, tempLogRepo, motilityLogRepo, activityLogRepo,
                estrusScoreRepo, contactTraceRepo,
                ranchQueryPort, ranchCommandPort,
                subscriptionPort,
                healthAnomalyService,
               feverService, digestiveService, estrusAnalysisService, epidemicService);

        // refreshSnapshot calls ensureSnapshotExists then findByLivestockId.
        doNothing().when(snapshotRepo).ensureSnapshotExists(anyLong(), anyLong());
    }

    @Test
    void processTelemetry_capsule_withTemperatures_expandsTo7Logs() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(10L, 10)).thenReturn(List.of());
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt())).thenReturn(List.of());

        List<BigDecimal> temperatures = List.of(
                bd("38.3"), bd("38.4"), bd("38.5"), bd("38.6"), bd("38.5"), bd("38.4"), bd("38.5"));

        Map<String, Object> readings = Map.of(
                "temperatures", temperatures,
                "gastricMotility", 500000L,
                "accelX", 10,
                "accelY", 20,
                "accelZ", 30
        );

        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        ArgumentCaptor<TemperatureLog> tempCaptor =
                ArgumentCaptor.forClass(TemperatureLog.class);
        ArgumentCaptor<RumenMotilityLog> motilityCaptor =
                ArgumentCaptor.forClass(RumenMotilityLog.class);
        verify(tempLogRepo, times(7)).save(tempCaptor.capture());
        verify(motilityLogRepo, times(1)).save(motilityCaptor.capture());
        tempCaptor.getAllValues().forEach(log ->
                assertEquals("DATAGEN", log.getSource()));
        assertEquals("DATAGEN", motilityCaptor.getValue().getSource());
    }

    @Test
    void processTelemetry_capsule_skipsAlreadyIngestedTemperaturePoint() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(10L, 10)).thenReturn(List.of());
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt()))
                .thenReturn(List.of());
        when(tempLogRepo.existsByDeviceIdAndRecordedAtAndSource(
                eq(51L), eq(Instant.parse("2026-06-04T10:00:00Z")), eq("DATAGEN")))
                .thenReturn(true);

        Map<String, Object> readings = Map.of(
                "temperatures", List.of(bd("38.3"), bd("38.4")),
                "gastricMotility", 500000L);

        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(tempLogRepo, times(1)).save(any());
    }

    @Test
    void processTelemetry_capsule_gastricMotilityDividedBy100000() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(10L, 10)).thenReturn(List.of());
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt())).thenReturn(List.of());

        Map<String, Object> readings = Map.of(
                "temperatures", List.of(bd("38.5")),
                "gastricMotility", 300000L
        );

        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(motilityLogRepo).save(argThat(log ->
                log.getFrequency().compareTo(new BigDecimal("3.00")) == 0));
    }

    @Test
    void processTelemetry_tracker_ingestActivityOnly() {
        when(snapshotRepo.findByLivestockId(5L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(5L), anyInt())).thenReturn(List.of());

        Map<String, Object> readings = Map.of(
                "stepCount", 1500,
                "distanceMeters", 450.0,
                "latitude", 28.229,
                "longitude", 112.938
        );

        service.processTelemetry(1L, 5L, 1L, DeviceType.TRACKER, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(tempLogRepo, never()).save(any());
        verify(activityLogRepo, times(1)).save(any());
    }

    @Test
    void processTelemetry_capsule_noTemperatures_skipsTempLog() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt())).thenReturn(List.of());

        Map<String, Object> readings = Map.of(
                "gastricMotility", 500000L
        );

        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(tempLogRepo, never()).save(any());
    }

    @Test
    void processTelemetry_createsNewSnapshotWhenNotExists() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(10L, 10)).thenReturn(List.of());
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt())).thenReturn(List.of());
        when(feverService.assessStatus(any(), any())).thenReturn(TempStatus.NORMAL);
        when(digestiveService.assessStatus(any(BigDecimal.class), any(BigDecimal.class))).thenReturn(MotilityStatus.NORMAL);

        Map<String, Object> readings = Map.of(
                "temperatures", List.of(bd("38.5")),
                "gastricMotility", 500000L
        );

        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(snapshotRepo).ensureSnapshotExists(eq(10L), eq(1L));
    }

    @Test
    void processTelemetry_capsule_singleTemperature_fallback() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(10L, 10)).thenReturn(List.of());
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt())).thenReturn(List.of());

        Map<String, Object> readings = Map.of("temperature", 38.5);
        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(tempLogRepo, times(1)).save(any());
    }

    @Test
    void processTelemetry_tracker_noActivityData_skipsActivityLog() {
        when(snapshotRepo.findByLivestockId(5L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(5L), anyInt())).thenReturn(List.of());

        Map<String, Object> readings = Map.of("batteryLevel", 85);
        service.processTelemetry(1L, 5L, 1L, DeviceType.TRACKER, readings,
                Instant.parse("2026-06-04T10:00:00Z"), "DATAGEN");

        verify(activityLogRepo, never()).save(any());
    }

    private BigDecimal bd(String val) {
        return new BigDecimal(val);
    }

    @Test
    void processTelemetry_missingSource_normalizesToUnknown() {
        when(snapshotRepo.findByLivestockId(10L)).thenReturn(Optional.of(new HealthSnapshot()));
        when(tempLogRepo.findByLivestockIdOrderByRecordedAtDesc(10L, 10)).thenReturn(List.of());
        when(estrusScoreRepo.findByLivestockIdOrderByScoredAtDesc(eq(10L), anyInt())).thenReturn(List.of());

        Map<String, Object> readings = Map.of("temperature", 38.5);
        service.processTelemetry(51L, 10L, 1L, DeviceType.CAPSULE, readings,
                Instant.parse("2026-06-04T10:00:00Z"), null);

        ArgumentCaptor<TemperatureLog> captor =
                ArgumentCaptor.forClass(TemperatureLog.class);
        verify(tempLogRepo).save(captor.capture());
        assertEquals("UNKNOWN", captor.getValue().getSource());
    }
}
