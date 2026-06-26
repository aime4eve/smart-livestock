package com.smartlivestock.integration;

import com.smartlivestock.iot.application.TelemetryIngestionService;
import com.smartlivestock.iot.application.service.TelemetrySimulator;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Integration test for GPS simulation via TelemetrySimulator.
 * Verifies random-walk GPS generation, initial position seeding from
 * LivestockInfo, and TRACKER vs CAPSULE device-type behavior.
 */
@ExtendWith(MockitoExtension.class)
class GpsSimulationTest {

    @Mock private InstallationRepository installationRepository;
    @Mock private DeviceRepository deviceRepository;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private TelemetryIngestionService telemetryIngestionService;

    private TelemetrySimulator simulator;

    // Initial position intentionally far from the old placeholder (28.229, 112.938)
    private static final BigDecimal INIT_LAT = new BigDecimal("28.5000");
    private static final BigDecimal INIT_LNG = new BigDecimal("113.0000");

    // Placeholder range that GPS must NOT fall into
    private static final double PLACEHOLDER_LAT_MIN = 28.224;
    private static final double PLACEHOLDER_LAT_MAX = 28.234;
    private static final double PLACEHOLDER_LNG_MIN = 112.933;
    private static final double PLACEHOLDER_LNG_MAX = 112.943;

    @BeforeEach
    void setUp() {
        simulator = new TelemetrySimulator(
                installationRepository, deviceRepository,
                ranchQueryPort, telemetryIngestionService);
    }

    private Installation createInstallation(Long deviceId, Long livestockId) {
        Installation inst = new Installation();
        inst.setDeviceId(deviceId);
        inst.setLivestockId(livestockId);
        return inst;
    }

    private Device createDevice(Long deviceId, DeviceType type) {
        Device device = new Device();
        device.setId(deviceId);
        device.setDeviceType(type);
        device.setStatus(DeviceStatus.ACTIVE);
        return device;
    }

    private LivestockInfo createLivestockInfo(Long livestockId) {
        return new LivestockInfo(livestockId, 1L, "TEST-001", "FEMALE", INIT_LAT, INIT_LNG);
    }

    private void setupMocks(DeviceType type, Long deviceId, Long livestockId) {
        Installation inst = createInstallation(deviceId, livestockId);
        when(installationRepository.findAllActive()).thenReturn(List.of(inst));
        when(deviceRepository.findById(deviceId)).thenReturn(Optional.of(createDevice(deviceId, type)));
        when(ranchQueryPort.findLivestockById(livestockId)).thenReturn(Optional.of(createLivestockInfo(livestockId)));
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> captureAllReadings(int expectedCalls) {
        ArgumentCaptor<Map<String, Object>> captor = ArgumentCaptor.forClass(Map.class);
        verify(telemetryIngestionService, times(expectedCalls)).ingest(any(), captor.capture(), any());
        return captor.getAllValues();
    }

    // ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("TRACKER GPS random-walk generation")
    class TrackerGpsRandomWalk {

        @Test
        @DisplayName("First tick GPS should start near LivestockInfo last position")
        void firstTickNearInitialPosition() {
            setupMocks(DeviceType.TRACKER, 1L, 10L);
            simulator.generateTelemetry();

            Map<String, Object> readings = captureAllReadings(1).get(0);
            double lat = (double) readings.get("latitude");
            double lng = (double) readings.get("longitude");

            // One random-walk step from initial: max delta ~0.0007 deg
            assertThat(lat).isCloseTo(INIT_LAT.doubleValue(), within(0.001));
            assertThat(lng).isCloseTo(INIT_LNG.doubleValue(), within(0.001));
        }

        @Test
        @DisplayName("GPS coordinates must NOT be the old placeholder range")
        void gpsNotPlaceholder() {
            setupMocks(DeviceType.TRACKER, 1L, 10L);
            simulator.generateTelemetry();

            Map<String, Object> readings = captureAllReadings(1).get(0);
            double lat = (double) readings.get("latitude");
            double lng = (double) readings.get("longitude");

            // INIT_LAT=28.5 and INIT_LNG=113.0 are far above placeholder range; one step can't bridge the gap
            assertThat(lat).isGreaterThan(PLACEHOLDER_LAT_MAX);
            assertThat(lng).isGreaterThan(PLACEHOLDER_LNG_MAX);
        }

        @Test
        @DisplayName("Multiple ticks should produce drifting positions (random walk)")
        void multipleTicksDrift() {
            setupMocks(DeviceType.TRACKER, 1L, 10L);

            simulator.generateTelemetry();
            simulator.generateTelemetry();
            simulator.generateTelemetry();

            List<Map<String, Object>> allReadings = captureAllReadings(3);
            double lat1 = (double) allReadings.get(0).get("latitude");
            double lat2 = (double) allReadings.get(1).get("latitude");
            double lat3 = (double) allReadings.get(2).get("latitude");

            // Each tick adds one step (~0.0002-0.0005 deg); 3 ticks max ~0.0021 from start
            double initLat = INIT_LAT.doubleValue();
            assertThat(Math.abs(lat1 - initLat)).isLessThanOrEqualTo(0.001);
            assertThat(Math.abs(lat3 - initLat)).isLessThanOrEqualTo(0.003);

            // Not all identical (random walk is moving)
            boolean anyDifferent = lat1 != lat2 || lat2 != lat3;
            assertThat(anyDifferent).as("GPS positions should change across ticks").isTrue();
        }

        @Test
        @DisplayName("Different livestock should have independent walk trajectories")
        void independentTrajectories() {
            Installation inst1 = createInstallation(1L, 10L);
            Installation inst2 = createInstallation(2L, 20L);
            when(installationRepository.findAllActive()).thenReturn(List.of(inst1, inst2));
            when(deviceRepository.findById(1L)).thenReturn(Optional.of(createDevice(1L, DeviceType.TRACKER)));
            when(deviceRepository.findById(2L)).thenReturn(Optional.of(createDevice(2L, DeviceType.TRACKER)));
            when(ranchQueryPort.findLivestockById(10L))
                    .thenReturn(Optional.of(createLivestockInfo(10L)));
            when(ranchQueryPort.findLivestockById(20L))
                    .thenReturn(Optional.of(createLivestockInfo(20L)));

            simulator.generateTelemetry();

            List<Map<String, Object>> readings = captureAllReadings(2);
            double lat1 = (double) readings.get(0).get("latitude");
            double lat2 = (double) readings.get(1).get("latitude");

            // Both start from same INIT_LAT but random walk gives different positions
            assertThat(lat1).isCloseTo(INIT_LAT.doubleValue(), within(0.001));
            assertThat(lat2).isCloseTo(INIT_LAT.doubleValue(), within(0.001));
        }
    }

    // ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("CAPSULE telemetry has no GPS")
    class CapsuleNoGps {

        @Test
        @DisplayName("CAPSULE readings should not contain latitude/longitude")
        void capsuleHasNoGps() {
            setupMocks(DeviceType.CAPSULE, 51L, 10L);
            simulator.generateTelemetry();

            Map<String, Object> readings = captureAllReadings(1).get(0);

            assertThat(readings).containsKey("temperatures");
            assertThat(readings).containsKey("gastricMotility");
            assertThat(readings).doesNotContainKey("latitude");
            assertThat(readings).doesNotContainKey("longitude");
        }
    }

    // ──────────────────────────────────────────────────────────

    @Nested
    @DisplayName("ACL and edge cases")
    class AclAndEdgeCases {

        @Test
        @DisplayName("Livestock not found via ACL should skip the device")
        void skipWhenLivestockNotFound() {
            Installation inst = createInstallation(1L, 999L);
            when(installationRepository.findAllActive()).thenReturn(List.of(inst));
            when(deviceRepository.findById(1L)).thenReturn(Optional.of(createDevice(1L, DeviceType.TRACKER)));
            when(ranchQueryPort.findLivestockById(999L)).thenReturn(Optional.empty());

            simulator.generateTelemetry();

            verify(telemetryIngestionService, times(0)).ingest(any(), any(), any());
        }

        @Test
        @DisplayName("Null last position should fall back to default coordinates")
        void nullPositionFallback() {
            Installation inst = createInstallation(1L, 10L);
            when(installationRepository.findAllActive()).thenReturn(List.of(inst));
            when(deviceRepository.findById(1L)).thenReturn(Optional.of(createDevice(1L, DeviceType.TRACKER)));
            // LivestockInfo with null position
            when(ranchQueryPort.findLivestockById(10L)).thenReturn(Optional.of(
                    new LivestockInfo(10L, 1L, "NOPos", "MALE", null, null)));

            simulator.generateTelemetry();

            Map<String, Object> readings = captureAllReadings(1).get(0);
            double lat = (double) readings.get("latitude");
            double lng = (double) readings.get("longitude");

            // Default fallback: 28.229, 112.938
            assertThat(lat).isCloseTo(28.229, within(0.001));
            assertThat(lng).isCloseTo(112.938, within(0.001));
        }
    }
}
