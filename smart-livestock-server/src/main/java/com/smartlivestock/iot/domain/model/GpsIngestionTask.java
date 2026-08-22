package com.smartlivestock.iot.domain.model;

import com.smartlivestock.shared.domain.Entity;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Durable write task for GPS data decoupled from telemetry ingestion.
 */
@Getter
@Setter
public class GpsIngestionTask extends Entity {
    private Long id;
    private Long deviceId;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal accuracy;
    private Instant recordedAt;
    private TelemetrySource source;
    private GpsIngestionTaskStatus status = GpsIngestionTaskStatus.PENDING;
    private int attempts;
    private Instant nextAttemptAt = Instant.now();
    private String lastError;
    private Instant createdAt;
    private Instant updatedAt;

    public void markFailed(String error, int maxAttempts, Instant retryAt) {
        attempts++;
        if (attempts >= maxAttempts) {
            status = GpsIngestionTaskStatus.FAILED;
        } else {
            status = GpsIngestionTaskStatus.PENDING;
            nextAttemptAt = retryAt;
        }
        lastError = error;
        touch();
    }

    private void touch() {
        updatedAt = Instant.now();
    }
}
