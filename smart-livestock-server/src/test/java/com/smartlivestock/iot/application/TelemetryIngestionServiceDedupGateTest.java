package com.smartlivestock.iot.application;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.iot.application.TelemetryDedupApplicationService.Observation;
import com.smartlivestock.iot.application.TelemetryDedupApplicationService.Result;
import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.GpsIngestionTaskRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.iot.domain.repository.TbDeviceBindingRepository;
import com.smartlivestock.iot.domain.port.RanchQueryPort;
import com.smartlivestock.iot.domain.service.GpsDistanceDerivationService;
import com.smartlivestock.ranch.application.signal.SignalRevisionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Branch coverage of the NIX-370 dedup gate on the ingest entry: only a
 * CANONICAL arbitration reaches ingest(); every duplicate class stops before
 * any repository work happens.
 */
@ExtendWith(MockitoExtension.class)
class TelemetryIngestionServiceDedupGateTest {

    @Mock
    private DeviceRepository deviceRepository;
    @Mock
    private DeviceTelemetryLogRepository deviceTelemetryLogRepository;
    @Mock
    private InstallationRepository installationRepository;
    @Mock
    private RanchQueryPort ranchQueryPort;
    @Mock
    private GpsIngestionTaskRepository gpsIngestionTaskRepository;
    @Mock
    private com.smartlivestock.ranch.domain.repository.AlertRepository alertRepository;
    @Mock
    private ApplicationEventPublisher eventPublisher;
    @Mock
    private GpsDistanceDerivationService gpsDistanceDerivationService;
    @Mock
    private com.smartlivestock.iot.application.GpsDataGovernanceService gpsDataGovernanceService;
    @Mock
    private com.smartlivestock.iot.application.DeviceLinkQualityService deviceLinkQualityService;
    @Mock
    private SignalRevisionService signalRevisionService;
    @Mock
    private TelemetryDedupApplicationService telemetryDedupService;

    private TelemetryIngestionService service;

    @BeforeEach
    void setUp() {
        service = new TelemetryIngestionService(
                deviceRepository, deviceTelemetryLogRepository, installationRepository,
                ranchQueryPort, gpsIngestionTaskRepository, alertRepository, eventPublisher,
                gpsDistanceDerivationService, gpsDataGovernanceService, deviceLinkQualityService,
                new ObjectMapper(), signalRevisionService, telemetryDedupService);
    }

    private Observation observation(Result result) {
        Observation observation = new Observation(122L, "THINGSBOARD", "tb-rest",
                "tb-uuid", Instant.ofEpochMilli(1000L), 1000L, "fp");
        when(telemetryDedupService.register(observation)).thenReturn(result);
        return observation;
    }

    private void activeDevice() {
        Device device = new Device(1L, "DEV-TB-1", DeviceType.TRACKER, null);
        device.setStatus(DeviceStatus.ACTIVE);
        device.setId(122L);
        // Only the CANONICAL branch reaches ingest; duplicate-class cases stop
        // before this lookup, hence lenient.
        org.mockito.Mockito.lenient().when(deviceRepository.findById(122L))
                .thenReturn(Optional.of(device));
    }

    @Test
    void canonicalObservationProceedsToIngest() {
        Observation observation = observation(Result.CANONICAL);
        activeDevice();

        var outcome = service.ingestWithDedup(observation,
                Map.of("battery", 99), Instant.ofEpochMilli(1000L));

        assertThat(outcome).isEqualTo(TelemetryIngestionService.DedupIngestOutcome.INGESTED);
        // ingest() really ran: its first repository touch (device lookup) happened.
        verify(deviceRepository).findById(122L);
    }

    @Test
    void duplicateClassesNeverReachIngest() {
        activeDevice();
        for (Result result : List.of(Result.MATCHED_DUPLICATE, Result.SOURCE_DUPLICATE,
                Result.AMBIGUOUS)) {
            Observation observation = observation(result);

            var outcome = service.ingestWithDedup(observation,
                    Map.of("battery", 99), Instant.ofEpochMilli(1000L));

            assertThat(outcome).isEqualTo(TelemetryIngestionService.DedupIngestOutcome.DUPLICATE);
            verify(deviceRepository, never()).findById(122L);
        }
        verify(deviceTelemetryLogRepository, never()).existsByDeviceIdAndReportTime(any(), any());
    }
}
