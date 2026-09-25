package com.smartlivestock.ranch.infrastructure.acl;

import com.smartlivestock.iot.domain.model.Device;
import com.smartlivestock.iot.domain.model.DeviceStatus;
import com.smartlivestock.iot.domain.model.Installation;
import com.smartlivestock.iot.domain.repository.DeviceRepository;
import com.smartlivestock.iot.domain.repository.DeviceTelemetryLogRepository;
import com.smartlivestock.iot.domain.repository.InstallationRepository;
import com.smartlivestock.ranch.domain.model.Livestock;
import com.smartlivestock.ranch.domain.port.DeviceSignalPort;
import com.smartlivestock.ranch.domain.repository.LivestockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Stream;

@Component
@RequiredArgsConstructor
public class DeviceSignalPortImpl implements DeviceSignalPort {

    private final InstallationRepository installationRepository;
    private final DeviceRepository deviceRepository;
    private final DeviceTelemetryLogRepository telemetryRepository;
    private final LivestockRepository livestockRepository;

    @Override
    public List<DeviceSignal> findInstalledDeviceSignals() {
        Map<Long, Installation> installationByDevice = new LinkedHashMap<>();
        for (Installation installation : installationRepository.findAllActive()) {
            installationByDevice.putIfAbsent(installation.getDeviceId(), installation);
        }

        List<DeviceSignal> signals = new ArrayList<>();
        for (Map.Entry<Long, Installation> entry : installationByDevice.entrySet()) {
            Device device = deviceRepository.findById(entry.getKey()).orElse(null);
            Livestock livestock = livestockRepository.findById(entry.getValue().getLivestockId()).orElse(null);
            if (device == null || livestock == null
                    || device.getStatus() != DeviceStatus.ACTIVE
                    || device.getDeletedAt() != null) {
                continue;
            }
            Instant telemetryAt = telemetryRepository.findLatestByDeviceId(device.getId())
                    .map(log -> log.getReportTime())
                    .orElse(null);
            Instant lastSeenAt = Stream.of(device.getLastOnlineAt(), device.getLastTelemetrySyncedAt(), telemetryAt)
                    .filter(Objects::nonNull)
                    .max(Instant::compareTo)
                    .orElse(null);
            signals.add(new DeviceSignal(
                    device.getId(),
                    livestock.getFarmId(),
                    livestock.getId(),
                    device.getDeviceCode(),
                    device.getRuntimeStatus(),
                    lastSeenAt
            ));
        }
        return signals;
    }
}
