package com.smartlivestock.datagen.domain.port;

import java.time.Instant;
import java.util.Map;

/** ACL port: datagen -> IoT. Feeds synthetic readings into IoT's standard ingestion pipeline. */
public interface TelemetryIngestionPort {
    void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt);
}
