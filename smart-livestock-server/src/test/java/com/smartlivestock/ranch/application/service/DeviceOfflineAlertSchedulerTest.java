package com.smartlivestock.ranch.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.port.DeviceSignalPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DeviceOfflineAlertSchedulerTest {

    @Mock private DeviceSignalPort deviceSignalPort;
    @Mock private AlertRepository alertRepository;

    private DeviceSignalPort.DeviceSignal signal(Instant lastSeen) {
        return new DeviceSignalPort.DeviceSignal(
                21L, 1L, 7L, "CAP-21", "offline", lastSeen);
    }

    @Test
    void opensOnlyOneActiveTicketWhenSilentOverThreshold() {
        when(deviceSignalPort.findInstalledDeviceSignals())
                .thenReturn(List.of(signal(Instant.now().minusSeconds(60 * 180))));
        when(alertRepository.findByDeviceIdAndTypeAndStatus(
                21L, AlertType.DEVICE_OFFLINE, AlertStatus.ACTIVE)).thenReturn(List.of());
        when(alertRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        new DeviceOfflineAlertScheduler(deviceSignalPort, alertRepository, new ObjectMapper(),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.application.signal.SignalRevisionService.class)
        ).reconcile();

        ArgumentCaptor<Alert> captor = ArgumentCaptor.forClass(Alert.class);
        verify(alertRepository).save(captor.capture());
        assertThat(captor.getValue().getType()).isEqualTo(AlertType.DEVICE_OFFLINE);
        assertThat(captor.getValue().getSeverity()).isEqualTo(Severity.WARNING);
        assertThat(captor.getValue().getFarmId()).isEqualTo(1L);
        assertThat(captor.getValue().getDeviceId()).isEqualTo(21L);
    }

    @Test
    void resolvesActiveTicketWhenDeviceReportsAgain() {
        DeviceSignalPort.DeviceSignal fresh = signal(Instant.now().minusSeconds(60));
        Alert active = new Alert(1L, 7L, null, 21L, AlertType.DEVICE_OFFLINE,
                Severity.WARNING, "offline");
        active.setId(31L);
        active.setStatus(AlertStatus.ACTIVE);
        when(deviceSignalPort.findInstalledDeviceSignals()).thenReturn(List.of(fresh));
        when(alertRepository.findByDeviceIdAndTypeAndStatus(
                21L, AlertType.DEVICE_OFFLINE, AlertStatus.ACTIVE)).thenReturn(List.of(active));
        when(alertRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        new DeviceOfflineAlertScheduler(deviceSignalPort, alertRepository, new ObjectMapper(),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.application.signal.SignalRevisionService.class)
        ).reconcile();

        verify(alertRepository).save(active);
        assertThat(active.getStatus()).isEqualTo(AlertStatus.AUTO_RESOLVED);
    }

    @Test
    void doesNotDuplicateActiveTicket() {
        DeviceSignalPort.DeviceSignal stale = signal(Instant.now().minusSeconds(60 * 180));
        Alert active = new Alert(1L, 7L, null, 21L, AlertType.DEVICE_OFFLINE,
                Severity.WARNING, "offline");
        when(deviceSignalPort.findInstalledDeviceSignals()).thenReturn(List.of(stale));
        when(alertRepository.findByDeviceIdAndTypeAndStatus(
                21L, AlertType.DEVICE_OFFLINE, AlertStatus.ACTIVE)).thenReturn(List.of(active));

        new DeviceOfflineAlertScheduler(deviceSignalPort, alertRepository, new ObjectMapper(),
                org.mockito.Mockito.mock(com.smartlivestock.ranch.application.signal.SignalRevisionService.class)
        ).reconcile();

        verify(alertRepository, never()).save(any());
    }
}
