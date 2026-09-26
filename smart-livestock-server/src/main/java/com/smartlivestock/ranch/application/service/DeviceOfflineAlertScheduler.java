package com.smartlivestock.ranch.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.domain.model.Alert;
import com.smartlivestock.ranch.domain.model.AlertStatus;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.domain.port.DeviceSignalPort;
import com.smartlivestock.ranch.domain.repository.AlertRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Opens one idempotent DEVICE_OFFLINE ticket per installed active device after
 * the unified silence threshold, and auto-resolves it when the device reports.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceOfflineAlertScheduler {

    private static final Duration OFFLINE_THRESHOLD = Duration.ofHours(2);

    private final DeviceSignalPort deviceSignalPort;
    private final AlertRepository alertRepository;
    private final ObjectMapper objectMapper;

    @Scheduled(fixedDelayString = "${alerts.device-offline.poll-ms:600000}")
    @Transactional
    public void reconcile() {
        try {
            int opened = 0;
            int resolved = 0;
            for (DeviceSignalPort.DeviceSignal signal : deviceSignalPort.findInstalledDeviceSignals()) {
                List<Alert> active = alertRepository.findByDeviceIdAndTypeAndStatus(
                        signal.deviceId(), AlertType.DEVICE_OFFLINE, AlertStatus.ACTIVE);
                if (isOffline(signal)) {
                    if (active.isEmpty()) {
                        open(signal);
                        opened++;
                    }
                } else {
                    for (Alert alert : active) {
                        alert.autoResolve();
                        alertRepository.save(alert);
                        resolved++;
                    }
                }
            }
            if (opened > 0 || resolved > 0) {
                log.info("Device offline reconciliation: opened={}, resolved={}", opened, resolved);
            }
        } catch (Exception e) {
            log.warn("Device offline reconciliation failed: {}", e.getMessage());
        }
    }

    private boolean isOffline(DeviceSignalPort.DeviceSignal signal) {
        return signal.lastSeenAt() == null
                || signal.lastSeenAt().isBefore(Instant.now().minus(OFFLINE_THRESHOLD));
    }

    private void open(DeviceSignalPort.DeviceSignal signal) {
        Alert alert = new Alert(signal.farmId(), signal.livestockId(), null, signal.deviceId(),
                AlertType.DEVICE_OFFLINE, Severity.WARNING, "Device offline: " + signal.deviceCode());
        alert.setMessageKey("alert.device.offline");
        alert.setSource("RULE");
        try {
            alert.setMessageArgs(objectMapper.writeValueAsString(List.of(signal.deviceCode())));
        } catch (Exception ignored) {
            alert.setMessageArgs("[]");
        }
        alertRepository.save(alert);
    }
}
