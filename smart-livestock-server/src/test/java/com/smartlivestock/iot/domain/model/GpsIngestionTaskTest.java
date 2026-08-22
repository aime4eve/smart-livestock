package com.smartlivestock.iot.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertEquals;

class GpsIngestionTaskTest {
    @Test
    void markFailed_underMaxAttempts_schedulesRetry() {
        GpsIngestionTask task = new GpsIngestionTask();
        Instant retryAt = Instant.parse("2026-08-22T10:01:00Z");

        task.markFailed("write failed", 3, retryAt);

        assertEquals(GpsIngestionTaskStatus.PENDING, task.getStatus());
        assertEquals(1, task.getAttempts());
        assertEquals(retryAt, task.getNextAttemptAt());
        assertEquals("write failed", task.getLastError());
    }

    @Test
    void markFailed_atMaxAttempts_marksFailed() {
        GpsIngestionTask task = new GpsIngestionTask();
        task.setAttempts(2);

        task.markFailed("write failed", 3, Instant.now());

        assertEquals(GpsIngestionTaskStatus.FAILED, task.getStatus());
        assertEquals(3, task.getAttempts());
    }
}
