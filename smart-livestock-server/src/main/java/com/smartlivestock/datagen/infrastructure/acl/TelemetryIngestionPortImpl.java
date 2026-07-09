package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.TelemetryIngestionPort;
import com.smartlivestock.iot.domain.model.TelemetrySource;
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
        ingest(deviceId, readings, recordedAt, TelemetrySource.DATAGEN);
    }

    @Override
    public void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt,
                       TelemetrySource source) {
        telemetryIngestionService.ingest(deviceId, readings, recordedAt, source);
    }
}
