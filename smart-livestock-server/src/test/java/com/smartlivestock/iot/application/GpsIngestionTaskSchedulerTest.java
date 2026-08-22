package com.smartlivestock.iot.application;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class GpsIngestionTaskSchedulerTest {
    @Mock
    private GpsIngestionTaskProcessor processor;

    private GpsIngestionTaskScheduler scheduler;

    @BeforeEach
    void setUp() {
        scheduler = new GpsIngestionTaskScheduler(processor);
        ReflectionTestUtils.setField(scheduler, "batchSize", 20);
        ReflectionTestUtils.setField(scheduler, "maxAttempts", 10);
        ReflectionTestUtils.setField(scheduler, "retryDelay", Duration.ofSeconds(30));
    }

    @Test
    void processReadyTasks_continuesAfterFailureAndRecordsRetry() {
        when(processor.findReadyTaskIds(any(Instant.class), anyInt()))
                .thenReturn(List.of(1L, 2L));
        when(processor.processTask(1L)).thenReturn(true);
        when(processor.processTask(2L)).thenThrow(new IllegalStateException("gps write failed"));

        scheduler.processReadyTasks();

        verify(processor).processTask(1L);
        verify(processor).processTask(2L);
        verify(processor).recordFailure(
                eq(2L), anyString(), eq(10), any(Instant.class));
    }
}
