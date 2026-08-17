package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.model.SynthesisScenario;
import com.smartlivestock.datagen.domain.port.DeviceQueryPort;
import com.smartlivestock.datagen.domain.port.FenceQueryPort;
import com.smartlivestock.datagen.domain.port.TelemetryIngestionPort;
import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import com.smartlivestock.datagen.domain.port.dto.CoordinateInfo;
import com.smartlivestock.datagen.domain.port.dto.FenceGeometryInfo;
import com.smartlivestock.datagen.domain.repository.SynthesisScenarioRepository;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SynthesisServiceTest {

    @Mock private TelemetryIngestionPort ingestionPort;
    @Mock private DeviceQueryPort deviceQueryPort;
    @Mock private FenceQueryPort fenceQueryPort;
    @Mock private SynthesisScenarioRepository scenarioRepository;

    private SynthesisService service;

    @Test
    void deviceIntervals_useDemoSamplingRates() {
        assertEquals(300, SynthesisService.TRACKER_INTERVAL.toSeconds());
        assertEquals(900, SynthesisService.CAPSULE_INTERVAL.toSeconds());
    }

    @BeforeEach
    void setUp() {
        service = new SynthesisService(
                ingestionPort, deviceQueryPort, fenceQueryPort, scenarioRepository,
                new GroundTruthLabelService(null));
    }

    @Test
    void generate_trackerOutsideFirstFence_resetsInsideFence() {
        Instant now = Instant.now();
        ActiveInstallationInfo installation = new ActiveInstallationInfo(
                5L, 1L, DeviceType.TRACKER, 29.0, 113.0);
        FenceGeometryInfo fence = new FenceGeometryInfo(1L, 1L, "HKT", List.of(
                new CoordinateInfo(28.0, 112.0),
                new CoordinateInfo(28.001, 112.0),
                new CoordinateInfo(28.001, 112.001),
                new CoordinateInfo(28.0, 112.001)));

        SynthesisScenario testScenario = scenario(now);
        when(deviceQueryPort.findActiveInstallationsByScenario(testScenario.getId()))
                .thenReturn(List.of(installation));
        when(fenceQueryPort.findActiveFencesByLivestockId(1L)).thenReturn(List.of(fence));

        service.generate(testScenario);

        ArgumentCaptor<Map<String, Object>> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(ingestionPort).ingest(eq(5L), readingsCaptor.capture(), any(Instant.class),
                eq(TelemetrySource.DATAGEN));
        double latitude = ((Number) readingsCaptor.getValue().get("latitude")).doubleValue();
        double longitude = ((Number) readingsCaptor.getValue().get("longitude")).doubleValue();
        assertTrue(latitude >= 28.0 && latitude <= 28.001);
        assertTrue(longitude >= 112.0 && longitude <= 112.001);
        assertTrue(Math.abs(latitude - 28.0005) < 0.0005);
        assertTrue(Math.abs(longitude - 112.0005) < 0.0005);
        assertTrue(latitude != 28.0005 || longitude != 112.0005);

        service.generate(testScenario);
        verify(ingestionPort, times(1)).ingest(
                eq(5L), any(), any(Instant.class), eq(TelemetrySource.DATAGEN));
    }

    @Test
    void generate_capsule_generatesHealthReadings() {
        Instant now = Instant.now();
        ActiveInstallationInfo installation = new ActiveInstallationInfo(
                51L, 1L, DeviceType.CAPSULE, null, null);

        SynthesisScenario testScenario = scenario(now);
        when(deviceQueryPort.findActiveInstallationsByScenario(testScenario.getId()))
                .thenReturn(List.of(installation));

        service.generate(testScenario);

        ArgumentCaptor<Map<String, Object>> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(ingestionPort).ingest(eq(51L), readingsCaptor.capture(), any(Instant.class),
                eq(TelemetrySource.DATAGEN));
        Map<String, Object> readings = readingsCaptor.getValue();
        assertEquals(7, ((List<?>) readings.get("temperatures")).size());
        assertTrue(((Number) readings.get("gastricMotility")).longValue() > 0);
        assertTrue(((Number) readings.get("batteryVoltage")).intValue() > 0);

        service.generate(testScenario);
        verify(ingestionPort, times(1)).ingest(
                eq(51L), any(), any(Instant.class), eq(TelemetrySource.DATAGEN));
    }

    @Test
    void generate_capsuleCreatesSharedStateBeforeTracker_trackerStillInitializesInFence() {
        Instant now = Instant.now();
        ActiveInstallationInfo capsule = new ActiveInstallationInfo(
                51L, 1L, DeviceType.CAPSULE, null, null);
        ActiveInstallationInfo tracker = new ActiveInstallationInfo(
                5L, 1L, DeviceType.TRACKER, 29.0, 113.0);
        FenceGeometryInfo fence = new FenceGeometryInfo(1L, 1L, "HKT", List.of(
                new CoordinateInfo(28.0, 112.0),
                new CoordinateInfo(28.001, 112.0),
                new CoordinateInfo(28.001, 112.001),
                new CoordinateInfo(28.0, 112.001)));

        SynthesisScenario testScenario = scenario(now);
        when(deviceQueryPort.findActiveInstallationsByScenario(testScenario.getId()))
                .thenReturn(List.of(capsule, tracker));
        when(fenceQueryPort.findActiveFencesByLivestockId(1L)).thenReturn(List.of(fence));

        service.generate(testScenario);

        ArgumentCaptor<Map<String, Object>> readingsCaptor = ArgumentCaptor.forClass(Map.class);
        verify(ingestionPort).ingest(
                eq(5L), readingsCaptor.capture(), any(Instant.class), eq(TelemetrySource.DATAGEN));
        double latitude = ((Number) readingsCaptor.getValue().get("latitude")).doubleValue();
        double longitude = ((Number) readingsCaptor.getValue().get("longitude")).doubleValue();
        assertTrue(latitude >= 28.0 && latitude <= 28.001);
        assertTrue(longitude >= 112.0 && longitude <= 112.001);
    }

    private static SynthesisScenario scenario(Instant now) {
        SynthesisScenario scenario = new SynthesisScenario();
        scenario.setName("demo");
        scenario.setType(ScenarioType.NORMAL);
        scenario.setStatus(ScenarioStatus.RUNNING);
        scenario.setWindowStart(now.minusSeconds(60));
        scenario.setWindowEnd(now.plusSeconds(3600));
        scenario.setIntervalSeconds(30);
        return scenario;
    }

    @Test
    void clearDeviceSchedules_removesOnlyRequestedDevices() {
        Instant now = Instant.now();
        SynthesisScenario testScenario = scenario(now);
        ActiveInstallationInfo installation = new ActiveInstallationInfo(
                5L, 1L, DeviceType.CAPSULE, null, null);
        when(deviceQueryPort.findActiveInstallationsByScenario(testScenario.getId()))
                .thenReturn(List.of(installation));

        service.clearDeviceSchedules(List.of(5L));
        service.generate(testScenario);
        verify(ingestionPort).ingest(
                eq(5L), any(), any(Instant.class), eq(TelemetrySource.DATAGEN));
    }
}
