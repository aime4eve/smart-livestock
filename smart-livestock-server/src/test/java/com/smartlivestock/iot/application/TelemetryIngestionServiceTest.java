package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.event.TelemetryReceivedEvent;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceTelemetryLog;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.GpsIngestionTask;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GpsIngestionTaskRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TelemetryIngestionServiceTest {

    @Mock private DeviceRepository deviceRepository;
    @Mock private DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    @Mock private InstallationRepository installationRepository;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private GpsIngestionTaskRepository gpsIngestionTaskRepository;
    @Mock private AlertRepository alertRepository;
    @Mock private ApplicationEventPublisher eventPublisher;

    private TelemetryIngestionService service;

    @BeforeEach
    void setUp() {
        service = new TelemetryIngestionService(
                deviceRepository, deviceTelemetryLogRepository, installationRepository,
                ranchQueryPort, gpsIngestionTaskRepository, alertRepository, eventPublisher,
                new com.fasterxml.jackson.databind.ObjectMapper());
    }

    private Device createCapsuleDevice(Long id) {
        Device d = new Device();
        d.setId(id);
        d.setDeviceType(DeviceType.CAPSULE);
        d.setStatus(DeviceStatus.ACTIVE);
        return d;
    }

    private Device createTrackerDevice(Long id) {
        Device d = new Device();
        d.setId(id);
        d.setDeviceType(DeviceType.TRACKER);
        d.setStatus(DeviceStatus.ACTIVE);
        return d;
    }

    private Device createEarTagDevice(Long id) {
        Device d = new Device();
        d.setId(id);
        d.setDeviceType(DeviceType.EAR_TAG);
        d.setStatus(DeviceStatus.ACTIVE);
        return d;
    }

    private Installation createInstallation(Long deviceId, Long livestockId) {
        Installation inst = new Installation(deviceId, livestockId, 1L);
        inst.setId(1L);
        return inst;
    }

    @Test
    void ingest_capsule_publishesGenericTelemetryEvent() {
        Device device = createCapsuleDevice(51L);
        Installation installation = createInstallation(51L, 10L);
        LivestockInfo livestockInfo = new LivestockInfo(10L, 1L, "C001", "FEMALE", new BigDecimal("28.2312"), new BigDecimal("112.9412"));

        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(10L)).thenReturn(Optional.of(livestockInfo));

        Instant recordedAt = Instant.parse("2026-06-04T10:00:00Z");
        Map<String, Object> readings = Map.of(
                "temperatures", java.util.List.of(new BigDecimal("38.6")),
                "gastricMotility", 500000L
        );

        service.ingest(51L, readings, recordedAt);

        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        Object published = eventCaptor.getValue();
        assertInstanceOf(TelemetryReceivedEvent.class, published);

        TelemetryReceivedEvent event = (TelemetryReceivedEvent) published;
        assertEquals(51L, event.getDeviceId());
        assertEquals(10L, event.getLivestockId());
        assertEquals(1L, event.getFarmId());
        assertEquals(DeviceType.CAPSULE, event.getDeviceType());
        assertEquals(readings, event.getReadings());
        assertEquals(recordedAt, event.getRecordedAt());
    }

    @Test
    void ingest_tracker_enqueuesGpsAndPublishesEvent() {
        Device device = createTrackerDevice(1L);
        Installation installation = createInstallation(1L, 5L);
        LivestockInfo livestockInfo = new LivestockInfo(5L, 1L, "C002", "MALE", null, null);

        when(deviceRepository.findById(1L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(1L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(5L)).thenReturn(Optional.of(livestockInfo));

        Instant recordedAt = Instant.parse("2026-06-04T10:00:00Z");
        Map<String, Object> readings = Map.of(
                "stepCount", 1500,
                "latitude", 28.229,
                "longitude", 112.938,
                "batteryLevel", 85
        );

        service.ingest(1L, readings, recordedAt);

        // Verify GPS was extracted and enqueued for the outbox worker
        ArgumentCaptor<GpsIngestionTask> taskCaptor = ArgumentCaptor.forClass(GpsIngestionTask.class);
        verify(gpsIngestionTaskRepository).enqueue(taskCaptor.capture());
        GpsIngestionTask task = taskCaptor.getValue();
        assertEquals(1L, task.getDeviceId());
        assertEquals(new BigDecimal("28.229"), task.getLatitude());
        assertEquals(new BigDecimal("112.938"), task.getLongitude());
        assertEquals(recordedAt, task.getRecordedAt());
        assertEquals(TelemetrySource.HTTP, task.getSource());

        // Verify telemetry event published
        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        TelemetryReceivedEvent event = (TelemetryReceivedEvent) eventCaptor.getValue();
        assertEquals(DeviceType.TRACKER, event.getDeviceType());
        assertEquals(1500, event.getReadings().get("stepCount"));
    }

    @Test
    void ingest_capsule_doesNotExtractGps() {
        Device device = createCapsuleDevice(51L);
        Installation installation = createInstallation(51L, 10L);
        LivestockInfo livestockInfo = new LivestockInfo(10L, 1L, "C001", "FEMALE", new BigDecimal("28.2312"), new BigDecimal("112.9412"));

        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(10L)).thenReturn(Optional.of(livestockInfo));

        Map<String, Object> readings = Map.of("temperatures", java.util.List.of(new BigDecimal("38.6")));
        service.ingest(51L, readings, Instant.now());

        verifyNoInteractions(gpsIngestionTaskRepository);
    }

    @Test
    void ingest_earTag_enqueuesGps() {
        Device device = createEarTagDevice(61L);
        when(deviceRepository.findById(61L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(61L)).thenReturn(Optional.empty());

        service.ingest(61L, Map.of(
                "latitude", 28.231,
                "longitude", 112.94
        ), Instant.parse("2026-08-31T01:00:00Z"));

        ArgumentCaptor<GpsIngestionTask> taskCaptor = ArgumentCaptor.forClass(GpsIngestionTask.class);
        verify(gpsIngestionTaskRepository).enqueue(taskCaptor.capture());
        assertEquals(61L, taskCaptor.getValue().getDeviceId());
        assertEquals(new BigDecimal("28.231"), taskCaptor.getValue().getLatitude());
        assertEquals(new BigDecimal("112.94"), taskCaptor.getValue().getLongitude());
    }

    @Test
    void ingest_deviceNotFound_throwsException() {
        when(deviceRepository.findById(999L)).thenReturn(Optional.empty());

        ApiException ex = assertThrows(ApiException.class,
                () -> service.ingest(999L, Map.of(), Instant.now()));
        assertEquals(ErrorCode.RESOURCE_NOT_FOUND, ex.getCode());
    }

    @Test
    void ingest_deviceNotActive_throwsException() {
        Device device = createCapsuleDevice(51L);
        device.setStatus(DeviceStatus.INVENTORY);
        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));

        ApiException ex = assertThrows(ApiException.class,
                () -> service.ingest(51L, Map.of("temperature", 38.5), Instant.now()));
        assertEquals(ErrorCode.STATE_CONFLICT, ex.getCode());
    }

    @Test
    void ingest_noActiveInstallation_succeedsWithoutLivestockId() {
        Device device = createCapsuleDevice(51L);
        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.empty());

        // Phase 3: telemetry ingestion without installation should succeed
        // (device ops data is valuable even before installation)
        assertDoesNotThrow(() -> service.ingest(51L, Map.of("temperature", 38.5), Instant.now()));

        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());
        TelemetryReceivedEvent event = (TelemetryReceivedEvent) eventCaptor.getValue();
        assertNull(event.getLivestockId());
    }

    @Test
    void ingest_invalidGpsFix_skipsOutboxAndStillPublishesTelemetry() {
        Device device = createTrackerDevice(9L);
        when(deviceRepository.findById(9L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(9L)).thenReturn(Optional.empty());

        service.ingest(9L, Map.of(
                "latitude", BigDecimal.ZERO,
                "longitude", BigDecimal.ZERO,
                "battery", 80
        ), Instant.parse("2026-08-22T10:00:00Z"), TelemetrySource.AGENTIC_PLATFORM);

        verifyNoInteractions(gpsIngestionTaskRepository);
        verify(eventPublisher).publishEvent(any(TelemetryReceivedEvent.class));
        verify(deviceTelemetryLogRepository).save(any(DeviceTelemetryLog.class));
    }

    @Test
    void ingest_outOfRangeGps_skipsOutboxAndStillIngestsTelemetry() {
        Device device = createTrackerDevice(10L);
        when(deviceRepository.findById(10L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(10L)).thenReturn(Optional.empty());

        service.ingest(10L, Map.of(
                "latitude", 999,
                "longitude", 112.938,
                "battery", 90
        ), Instant.parse("2026-08-22T10:00:00Z"), TelemetrySource.AGENTIC_PLATFORM);

        verifyNoInteractions(gpsIngestionTaskRepository);
        verify(eventPublisher).publishEvent(any(TelemetryReceivedEvent.class));
        verify(deviceTelemetryLogRepository).save(any(DeviceTelemetryLog.class));
    }

    @Test
    void ingest_usesCurrentTimeWhenRecordedAtIsNull() {
        Device device = createCapsuleDevice(51L);
        Installation installation = createInstallation(51L, 10L);
        LivestockInfo livestockInfo = new LivestockInfo(10L, 1L, "C001", "FEMALE", new BigDecimal("28.2312"), new BigDecimal("112.9412"));

        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(10L)).thenReturn(Optional.of(livestockInfo));

        service.ingest(51L, Map.of("temperature", 38.5), null);

        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        TelemetryReceivedEvent event = (TelemetryReceivedEvent) eventCaptor.getValue();
        assertNotNull(event.getRecordedAt());
    }

    // --- NIX-79: MANUAL_IMPORT isolation (spec §4.4) ---

    @Test
    void ingest_manualImport_skipsRuntimeSnapshot_logsHistoricalValues() {
        Device device = createTrackerDevice(7L);
        device.setDeviceCode("TRK-7");
        device.setBatteryLevel(50);
        device.setRssi(-70);
        Instant previousOnlineAt = Instant.parse("2026-07-29T00:00:00Z");
        device.setLastOnlineAt(previousOnlineAt);

        when(deviceRepository.findById(7L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.empty());

        Instant recordedAt = Instant.parse("2026-07-23T16:09:11Z");
        Map<String, Object> readings = new java.util.HashMap<>(Map.of(
                "battery", 99,
                "rssi", -99,
                "snr", new BigDecimal("-9"),
                "latitude", new BigDecimal("28.246777"),
                "longitude", new BigDecimal("112.851138"),
                "stepCount", 27
        ));

        service.ingest(7L, readings, recordedAt, TelemetrySource.MANUAL_IMPORT);

        // Runtime snapshot untouched: no save, no field rewrite
        verify(deviceRepository, never()).save(any());
        assertEquals(50, device.getBatteryLevel());
        assertEquals(-70, device.getRssi());
        assertEquals(previousOnlineAt, device.getLastOnlineAt());

        // Telemetry log row carries the row's own historical values + source
        ArgumentCaptor<DeviceTelemetryLog> logCaptor = ArgumentCaptor.forClass(DeviceTelemetryLog.class);
        verify(deviceTelemetryLogRepository).save(logCaptor.capture());
        DeviceTelemetryLog logEntry = logCaptor.getValue();
        assertEquals(99, logEntry.getBatteryLevel());
        assertEquals(-99, logEntry.getRssi());
        assertEquals(new BigDecimal("-9"), logEntry.getSnr());
        assertEquals(TelemetrySource.MANUAL_IMPORT, logEntry.getSource());
        assertEquals(recordedAt, logEntry.getReportTime());

        // GPS enqueued with MANUAL_IMPORT source; no alerts; event still published
        ArgumentCaptor<GpsIngestionTask> taskCaptor = ArgumentCaptor.forClass(GpsIngestionTask.class);
        verify(gpsIngestionTaskRepository).enqueue(taskCaptor.capture());
        assertEquals(7L, taskCaptor.getValue().getDeviceId());
        assertEquals(new BigDecimal("28.246777"), taskCaptor.getValue().getLatitude());
        assertEquals(new BigDecimal("112.851138"), taskCaptor.getValue().getLongitude());
        assertEquals(recordedAt, taskCaptor.getValue().getRecordedAt());
        assertEquals(TelemetrySource.MANUAL_IMPORT, taskCaptor.getValue().getSource());
        verifyNoInteractions(alertRepository);
        verify(eventPublisher).publishEvent(any(TelemetryReceivedEvent.class));
    }

    @Test
    void ingest_platformDeviceFault_persistsLocalizedMessageKey() {
        Device device = createTrackerDevice(7L);
        device.setDeviceCode("TRK-7");
        device.setTenantId(1L);
        device.setBatteryLevel(50);
        when(deviceRepository.findById(7L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.empty());

        service.ingest(7L, Map.of("antiDisassemblyStatus", 1),
                Instant.now(), TelemetrySource.AGENTIC_PLATFORM);

        ArgumentCaptor<Alert> alertCaptor = ArgumentCaptor.forClass(Alert.class);
        verify(alertRepository).save(alertCaptor.capture());
        assertEquals("alert.device.tamper", alertCaptor.getValue().getMessageKey());
        assertTrue(alertCaptor.getValue().getMessageArgs().contains("TRK-7"));
    }

    @Test
    void ingest_thingsBoardDeviceFault_triggersDeviceAlert() {
        Device device = createTrackerDevice(7L);
        device.setDeviceCode("TRK-TB");
        when(deviceRepository.findById(7L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(7L)).thenReturn(Optional.empty());

        service.ingest(7L, Map.of("antiDisassemblyStatus", 1),
                Instant.now(), TelemetrySource.THINGSBOARD);

        ArgumentCaptor<Alert> alertCaptor = ArgumentCaptor.forClass(Alert.class);
        verify(alertRepository).save(alertCaptor.capture());
        assertEquals("alert.device.tamper", alertCaptor.getValue().getMessageKey());
    }

    @Test
    void ingest_agenticPlatform_updatesSnapshotAndWritesSource() {
        Device device = createTrackerDevice(8L);

        when(deviceRepository.findById(8L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(8L)).thenReturn(Optional.empty());

        Instant recordedAt = Instant.parse("2026-07-28T10:00:00Z");
        Map<String, Object> readings = new java.util.HashMap<>(Map.of(
                "battery", 80,
                "latitude", new BigDecimal("28.23"),
                "longitude", new BigDecimal("112.94")
        ));

        service.ingest(8L, readings, recordedAt, TelemetrySource.AGENTIC_PLATFORM);

        // Snapshot still updated for live sources
        assertEquals(80, device.getBatteryLevel());
        assertNotNull(device.getLastOnlineAt());
        verify(deviceRepository, atLeastOnce()).save(device);
        // Sync cursor advanced only for AGENTIC_PLATFORM
        assertEquals(recordedAt, device.getLastTelemetrySyncedAt());

        ArgumentCaptor<DeviceTelemetryLog> logCaptor = ArgumentCaptor.forClass(DeviceTelemetryLog.class);
        verify(deviceTelemetryLogRepository).save(logCaptor.capture());
        assertEquals(TelemetrySource.AGENTIC_PLATFORM, logCaptor.getValue().getSource());
        assertEquals(80, logCaptor.getValue().getBatteryLevel());

        ArgumentCaptor<GpsIngestionTask> taskCaptor = ArgumentCaptor.forClass(GpsIngestionTask.class);
        verify(gpsIngestionTaskRepository).enqueue(taskCaptor.capture());
        assertEquals(TelemetrySource.AGENTIC_PLATFORM, taskCaptor.getValue().getSource());
        assertEquals(recordedAt, taskCaptor.getValue().getRecordedAt());
    }
}
