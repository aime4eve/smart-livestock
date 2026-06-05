package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.event.TelemetryReceivedEvent;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.port.dto.LivestockInfo;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
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
    @Mock private InstallationRepository installationRepository;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private GpsLogApplicationService gpsLogApplicationService;
    @Mock private ApplicationEventPublisher eventPublisher;

    private TelemetryIngestionService service;

    @BeforeEach
    void setUp() {
        service = new TelemetryIngestionService(
                deviceRepository, installationRepository,
                ranchQueryPort, gpsLogApplicationService, eventPublisher);
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

    private Installation createInstallation(Long deviceId, Long livestockId) {
        Installation inst = new Installation(deviceId, livestockId, 1L);
        inst.setId(1L);
        return inst;
    }

    @Test
    void ingest_capsule_publishesGenericTelemetryEvent() {
        Device device = createCapsuleDevice(51L);
        Installation installation = createInstallation(51L, 10L);
        LivestockInfo livestockInfo = new LivestockInfo(10L, 1L, "C001", "FEMALE");

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
    void ingest_tracker_extractsGpsAndPublishesEvent() {
        Device device = createTrackerDevice(1L);
        Installation installation = createInstallation(1L, 5L);
        LivestockInfo livestockInfo = new LivestockInfo(5L, 1L, "C002", "MALE");

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

        // Verify GPS was extracted and logged
        verify(gpsLogApplicationService).logGps(eq(1L),
                eq(new BigDecimal("28.229")), eq(new BigDecimal("112.938")),
                isNull(), eq(recordedAt));

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
        LivestockInfo livestockInfo = new LivestockInfo(10L, 1L, "C001", "FEMALE");

        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(10L)).thenReturn(Optional.of(livestockInfo));

        Map<String, Object> readings = Map.of("temperatures", java.util.List.of(new BigDecimal("38.6")));
        service.ingest(51L, readings, Instant.now());

        verify(gpsLogApplicationService, never()).logGps(any(), any(), any(), any(), any());
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
    void ingest_noActiveInstallation_throwsException() {
        Device device = createCapsuleDevice(51L);
        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.empty());

        ApiException ex = assertThrows(ApiException.class,
                () -> service.ingest(51L, Map.of("temperature", 38.5), Instant.now()));
        assertEquals(ErrorCode.RESOURCE_NOT_FOUND, ex.getCode());
    }

    @Test
    void ingest_usesCurrentTimeWhenRecordedAtIsNull() {
        Device device = createCapsuleDevice(51L);
        Installation installation = createInstallation(51L, 10L);
        LivestockInfo livestockInfo = new LivestockInfo(10L, 1L, "C001", "FEMALE");

        when(deviceRepository.findById(51L)).thenReturn(Optional.of(device));
        when(installationRepository.findActiveByDeviceId(51L)).thenReturn(Optional.of(installation));
        when(ranchQueryPort.findLivestockById(10L)).thenReturn(Optional.of(livestockInfo));

        service.ingest(51L, Map.of("temperature", 38.5), null);

        ArgumentCaptor<Object> eventCaptor = ArgumentCaptor.forClass(Object.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        TelemetryReceivedEvent event = (TelemetryReceivedEvent) eventCaptor.getValue();
        assertNotNull(event.getRecordedAt());
    }
}
