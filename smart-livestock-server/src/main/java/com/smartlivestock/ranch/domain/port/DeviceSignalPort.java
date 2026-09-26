package com.smartlivestock.ranch.domain.port;

import java.time.Instant;
import java.util.List;

/** Read model for runtime device signals that can raise ranch alerts. */
public interface DeviceSignalPort {

    List<DeviceSignal> findInstalledDeviceSignals();

    record DeviceSignal(
            Long deviceId,
            Long farmId,
            Long livestockId,
            String deviceCode,
            String runtimeStatus,
            Instant lastSeenAt
    ) {}
}
