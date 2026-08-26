package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.domain.model.ScenarioStatus;
import com.smartlivestock.datagen.domain.model.ScenarioType;
import com.smartlivestock.datagen.domain.model.DatagenFarmRules;
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

import java.lang.reflect.Field;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
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
    void deviceIntervals_useFarmRules() throws Exception {
        Instant now = Instant.now();
        SynthesisScenario testScenario = scenario(now);
        ActiveInstallationInfo tracker = new ActiveInstallationInfo(
                5L, 1L, DeviceType.TRACKER, null, null,
                new DatagenFarmRules(61, 900, 0, 5, 10, 0,
                        120, 130, 120, 130));
        ActiveInstallationInfo capsule = new ActiveInstallationInfo(
                6L, 2L, DeviceType.CAPSULE, null, null,
                new DatagenFarmRules(300, 301, 0, 5, 10, 0,
                        120, 130, 120, 130));
        when(deviceQueryPort.findActiveInstallationsByScenario(testScenario.getId()))
                .thenReturn(List.of(tracker, capsule));

        service.generate(testScenario);

        Field nextDueField = SynthesisService.class.getDeclaredField("nextDueByDevice");
        nextDueField.setAccessible(true);
        @SuppressWarnings("unchecked")
        Map<Long, Instant> nextDue = (Map<Long, Instant>) nextDueField.get(service);
        assertTrue(nextDue.get(5L).isAfter(Instant.now().plusSeconds(60)));
        assertTrue(nextDue.get(6L).isAfter(Instant.now().plusSeconds(300)));
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
    void generate_boundedExcursion_returnsContinuously() throws Exception {
        FenceGeometryInfo fence = new FenceGeometryInfo(1L, 1L, "HKT", List.of(
                new CoordinateInfo(28.0, 112.0),
                new CoordinateInfo(28.001, 112.0),
                new CoordinateInfo(28.001, 112.001),
                new CoordinateInfo(28.0, 112.001)));
        DatagenFarmRules rules = new DatagenFarmRules(
                60, 900, 1.0, 5, 5,
                0, 120, 130, 120, 130);
        ActiveInstallationInfo installation = new ActiveInstallationInfo(
                5L, 1L, DeviceType.TRACKER, 28.0005, 112.0005, rules);
        SynthesisScenario testScenario = scenario(Instant.now());
        when(deviceQueryPort.findActiveInstallationsByScenario(testScenario.getId()))
                .thenReturn(List.of(installation));
        when(fenceQueryPort.findActiveFencesByLivestockId(1L)).thenReturn(List.of(fence));

        service.generate(testScenario);
        int excursionCallCount = 1;
        while (!isOutsideRectangle(latestPosition(service), fence) && excursionCallCount < 10) {
            service.clearDeviceSchedules(List.of(5L));
            service.generate(testScenario);
            excursionCallCount++;
        }

        Field statesField = SynthesisService.class.getDeclaredField("states");
        statesField.setAccessible(true);
        @SuppressWarnings("unchecked")
        Map<Long, SynthesisState> states = (Map<Long, SynthesisState>) statesField.get(service);
        states.get(1L).fenceExcursionEnd = Instant.now().minusSeconds(1);

        for (int i = 0; i < 8; i++) {
            service.clearDeviceSchedules(List.of(5L));
            service.generate(testScenario);
        }

        ArgumentCaptor<Map<String, Object>> readingsCaptor =
                ArgumentCaptor.forClass(Map.class);
        verify(ingestionPort, times(excursionCallCount + 8)).ingest(
                eq(5L), readingsCaptor.capture(), any(Instant.class),
                eq(TelemetrySource.DATAGEN));
        List<double[]> positions = readingsCaptor.getAllValues().stream()
                .map(value -> new double[]{
                        ((Number) value.get("latitude")).doubleValue(),
                        ((Number) value.get("longitude")).doubleValue()})
                .toList();

        int excursionIndex = excursionCallCount - 1;
        assertTrue(isOutsideRectangle(positions.get(excursionIndex), fence),
                "probability 1 should start an excursion");
        double previousDistance = rectangleBoundaryDistanceMeters(
                positions.get(excursionIndex), fence);
        assertTrue(previousDistance <= 40, "excursion should stay near the fence");

        boolean returned = false;
        for (int i = excursionIndex + 1; i < positions.size(); i++) {
            if (!isOutsideRectangle(positions.get(i), fence)) {
                returned = true;
                break;
            }
            double distance = rectangleBoundaryDistanceMeters(positions.get(i), fence);
            assertTrue(distance <= 40, "excursion distance must stay bounded");
            assertTrue(distance <= previousDistance,
                    "return movement should move closer to the fence");
            previousDistance = distance;
        }
        assertTrue(returned, "livestock should return to the fence");
    }

    @Test
    void generate_capsuleCurves_areDeterministicAndSmooth() throws Exception {
        ActiveInstallationInfo installation = new ActiveInstallationInfo(
                51L, 1L, DeviceType.CAPSULE, null, null);
        SynthesisState state = SynthesisState.create(1L, installation);
        DatagenFarmRules rules = new DatagenFarmRules(
                300, 900, 0.02, 10, 30,
                0, 240, 480, 480, 720);
        var method = SynthesisService.class.getDeclaredMethod(
                "generateCapsuleBaseline", SynthesisState.class, Instant.class,
                DatagenFarmRules.class);
        method.setAccessible(true);

        Instant now = Instant.parse("2026-08-26T08:00:00Z");
        Map<String, Object> first = (Map<String, Object>) method.invoke(service, state, now, rules);
        Map<String, Object> second = (Map<String, Object>) method.invoke(service, state, now, rules);
        assertEquals(first.get("temperatures"), second.get("temperatures"));
        assertEquals(first.get("gastricMotility"), second.get("gastricMotility"));

        Map<String, Object> next = (Map<String, Object>) method.invoke(
                service, state, now.plus(Duration.ofMinutes(5)), rules);
        List<? extends Number> temperatures = (List<? extends Number>) first.get("temperatures");
        List<? extends Number> nextTemperatures = (List<? extends Number>) next.get("temperatures");
        for (int i = 1; i < temperatures.size(); i++) {
            double delta = Math.abs(temperatures.get(i).doubleValue()
                    - temperatures.get(i - 1).doubleValue());
            assertTrue(delta <= 0.08, "normal temperature should move smoothly");
        }
        long motilityDelta = Math.abs(
                ((Number) first.get("gastricMotility")).longValue()
                        - ((Number) next.get("gastricMotility")).longValue());
        assertTrue(motilityDelta <= 20_000, "normal motility should move smoothly");
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

    private static boolean isOutsideRectangle(double[] position, FenceGeometryInfo fence) {
        double minLat = fence.vertices().stream().mapToDouble(CoordinateInfo::latitude).min().orElseThrow();
        double maxLat = fence.vertices().stream().mapToDouble(CoordinateInfo::latitude).max().orElseThrow();
        double minLng = fence.vertices().stream().mapToDouble(CoordinateInfo::longitude).min().orElseThrow();
        double maxLng = fence.vertices().stream().mapToDouble(CoordinateInfo::longitude).max().orElseThrow();
        return position[0] < minLat || position[0] > maxLat
                || position[1] < minLng || position[1] > maxLng;
    }

    private static double[] latestPosition(SynthesisService service) throws Exception {
        Field statesField = SynthesisService.class.getDeclaredField("states");
        statesField.setAccessible(true);
        @SuppressWarnings("unchecked")
        Map<Long, SynthesisState> states = (Map<Long, SynthesisState>) statesField.get(service);
        SynthesisState state = states.get(1L);
        return new double[]{state.currentLat, state.currentLng};
    }

    private static double rectangleBoundaryDistanceMeters(
            double[] position, FenceGeometryInfo fence) {
        double minLat = fence.vertices().stream().mapToDouble(CoordinateInfo::latitude).min().orElseThrow();
        double maxLat = fence.vertices().stream().mapToDouble(CoordinateInfo::latitude).max().orElseThrow();
        double minLng = fence.vertices().stream().mapToDouble(CoordinateInfo::longitude).min().orElseThrow();
        double maxLng = fence.vertices().stream().mapToDouble(CoordinateInfo::longitude).max().orElseThrow();
        double latDistance = position[0] < minLat ? minLat - position[0]
                : position[0] > maxLat ? position[0] - maxLat : 0;
        double lngDistance = position[1] < minLng ? minLng - position[1]
                : position[1] > maxLng ? position[1] - maxLng : 0;
        return Math.hypot(latDistance * 111_000d,
                lngDistance * 111_000d * Math.cos(Math.toRadians(position[0])));
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
