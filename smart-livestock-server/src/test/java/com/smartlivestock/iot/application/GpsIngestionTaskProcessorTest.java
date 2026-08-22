package com.smartlivestock.iot.application;

import com.smartlivestock.iot.domain.model.GpsIngestionTask;
import com.smartlivestock.iot.domain.model.GpsIngestionTaskStatus;
import com.smartlivestock.iot.domain.model.TelemetrySource;
import com.smartlivestock.iot.domain.repository.GpsIngestionTaskRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GpsIngestionTaskProcessorTest {
    @Mock
    private GpsIngestionTaskRepository taskRepository;

    @Mock
    private GpsLogApplicationService gpsLogApplicationService;

    @InjectMocks
    private GpsIngestionTaskProcessor processor;

    private GpsIngestionTask task;

    @BeforeEach
    void setUp() {
        task = new GpsIngestionTask();
        task.setId(1L);
        task.setDeviceId(2L);
        task.setLatitude(new BigDecimal("28.2290000"));
        task.setLongitude(new BigDecimal("112.9380000"));
        task.setRecordedAt(Instant.parse("2026-08-22T10:00:00Z"));
        task.setSource(TelemetrySource.AGENTIC_PLATFORM);
        task.setStatus(GpsIngestionTaskStatus.PENDING);
        task.setNextAttemptAt(Instant.parse("2026-08-22T09:59:59Z"));
    }

    @Test
    void processTask_writesGpsAndRemovesCompletedTask() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));

        boolean processed = processor.processTask(1L);

        assertTrue(processed);
        verify(gpsLogApplicationService).logGps(
                task.getDeviceId(), task.getLatitude(), task.getLongitude(),
                task.getAccuracy(), task.getRecordedAt(), task.getSource());
        verify(taskRepository).delete(task);
        verify(taskRepository, never()).save(task);
    }

    @Test
    void processTask_notReady_skipsGpsWrite() {
        task.setNextAttemptAt(Instant.now().plusSeconds(30));
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));

        assertFalse(processor.processTask(1L));

        verify(gpsLogApplicationService, never()).logGps(
                org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
    }

    @Test
    void processTask_failedStatus_skipsGpsWrite() {
        task.setStatus(GpsIngestionTaskStatus.FAILED);
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));

        assertFalse(processor.processTask(1L));
        verify(taskRepository, never()).delete(task);
    }

    @Test
    void processTask_gpsWriteFailure_propagatesForSchedulerRetry() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));
        org.mockito.Mockito.doThrow(new IllegalStateException("gps unavailable"))
                .when(gpsLogApplicationService)
                .logGps(task.getDeviceId(), task.getLatitude(), task.getLongitude(),
                        task.getAccuracy(), task.getRecordedAt(), task.getSource());

        assertThrows(IllegalStateException.class, () -> processor.processTask(1L));

        verify(taskRepository, never()).delete(task);
    }

    @Test
    void recordFailure_updatesTaskForRetry() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));
        Instant retryAt = Instant.parse("2026-08-22T10:01:00Z");

        processor.recordFailure(1L, "gps unavailable", 10, retryAt);

        assertEquals(1, task.getAttempts());
        assertEquals(retryAt, task.getNextAttemptAt());
        assertEquals("gps unavailable", task.getLastError());
        verify(taskRepository).save(task);
    }
}
