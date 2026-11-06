package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.CalvingPredictionApplicationService;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository.ActiveLivestock;
import com.smartlivestock.health.infrastructure.config.CalvingPredictionProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CalvingPredictionSchedulerTest {

    @Mock private CalvingPredictionApplicationService calvingPredictionService;
    @Mock private HealthSnapshotRepository snapshotRepo;

    private CalvingPredictionScheduler scheduler;
    private CalvingPredictionProperties properties;

    @BeforeEach
    void setUp() {
        properties = new CalvingPredictionProperties();
        scheduler = new CalvingPredictionScheduler(calvingPredictionService, snapshotRepo, properties);
    }

    @Test
    void dispatchesEachActiveLivestock() {
        when(snapshotRepo.findRecentlyActive(any(Instant.class), eq(properties.getMaxPerPoll())))
                .thenReturn(List.of(
                        new ActiveLivestock(100L, 1L, "THINGSBOARD"),
                        new ActiveLivestock(101L, 2L, "DATAGEN")));

        scheduler.evaluateActiveLivestock();

        verify(calvingPredictionService).evaluateHead(100L);
        verify(calvingPredictionService).evaluateHead(101L);
    }

    @Test
    void oneFailingDispatchDoesNotStopTheBatch() {
        when(snapshotRepo.findRecentlyActive(any(Instant.class), anyInt()))
                .thenReturn(List.of(
                        new ActiveLivestock(100L, 1L, "UNKNOWN"),
                        new ActiveLivestock(101L, 1L, "UNKNOWN")));
        doThrow(new IllegalStateException("commit failed"))
                .when(calvingPredictionService).evaluateHead(100L);

        scheduler.evaluateActiveLivestock();

        verify(calvingPredictionService).evaluateHead(101L);
    }

    @Test
    void noActiveLivestock_dispatchesNothing() {
        when(snapshotRepo.findRecentlyActive(any(Instant.class), anyInt())).thenReturn(List.of());

        scheduler.evaluateActiveLivestock();

        verify(calvingPredictionService, never()).evaluateHead(any());
    }

    @Test
    void disabledFlag_skipsQueryAndDispatch() {
        properties.setEnabled(false);

        scheduler.evaluateActiveLivestock();

        verify(snapshotRepo, never()).findRecentlyActive(any(Instant.class), anyInt());
        verify(calvingPredictionService, never()).evaluateHead(any());
    }
}
