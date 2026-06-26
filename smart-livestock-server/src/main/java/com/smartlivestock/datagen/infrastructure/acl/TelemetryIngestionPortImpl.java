package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.TelemetryIngestionPort;
import com.smartlivestock.iot.application.TelemetryIngestionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class TelemetryIngestionPortImpl implements TelemetryIngestionPort {
    private final TelemetryIngestionService telemetryIngestionService;

    @Override
    public void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt) {
        telemetryIngestionService.ingest(deviceId, readings, recordedAt);
    }
}
