package com.smartlivestock.health.application;

import com.smartlivestock.health.application.service.HealthAnomalyService;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository.ActiveLivestock;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HealthAnomalySchedulerTest {

    @Mock private HealthAnomalyService healthAnomalyService;
    @Mock private HealthSnapshotRepository snapshotRepo;

    private HealthAnomalyScheduler scheduler;

    @BeforeEach
    void setUp() {
        scheduler = new HealthAnomalyScheduler(healthAnomalyService, snapshotRepo);
        ReflectionTestUtils.setField(scheduler, "enabled", true);
        ReflectionTestUtils.setField(scheduler, "activeWindowMinutes", 120);
        ReflectionTestUtils.setField(scheduler, "maxPerPoll", 200);
        ReflectionTestUtils.setField(scheduler, "tenantId", 1L);
    }

    @Test
    void dispatchesEachActiveLivestockWithItsOwnSource() {
        when(snapshotRepo.findRecentlyActive(any(Instant.class), eq(200)))
                .thenReturn(List.of(
                        new ActiveLivestock(100L, 1L, "THINGSBOARD"),
                        new ActiveLivestock(101L, 2L, "DATAGEN")));

        scheduler.assessActiveLivestock();

        verify(healthAnomalyService).assess(1L, 1L, 100L, "THINGSBOARD");
        verify(healthAnomalyService).assess(1L, 2L, 101L, "DATAGEN");
    }

    @Test
    void oneFailingLivestockDoesNotStopTheBatch() {
        when(snapshotRepo.findRecentlyActive(any(Instant.class), anyInt()))
                .thenReturn(List.of(
                        new ActiveLivestock(100L, 1L, "UNKNOWN"),
                        new ActiveLivestock(101L, 1L, "UNKNOWN")));
        org.mockito.Mockito.doThrow(new IllegalStateException("boom"))
                .when(healthAnomalyService).assess(1L, 1L, 100L, "UNKNOWN");

        scheduler.assessActiveLivestock();

        verify(healthAnomalyService).assess(1L, 1L, 101L, "UNKNOWN");
    }

    @Test
    void noActiveLivestock_dispatchesNothing() {
        when(snapshotRepo.findRecentlyActive(any(Instant.class), anyInt()))
                .thenReturn(List.of());

        scheduler.assessActiveLivestock();

        verify(healthAnomalyService, never()).assess(any(Long.class), any(Long.class),
                any(Long.class), any(String.class));
    }

    @Test
    void disabledFlag_skipsQueryAndDispatch() {
        ReflectionTestUtils.setField(scheduler, "enabled", false);

        scheduler.assessActiveLivestock();

        verify(snapshotRepo, never()).findRecentlyActive(any(Instant.class), anyInt());
        verify(healthAnomalyService, never()).assess(any(Long.class), any(Long.class),
                any(Long.class), any(String.class));
    }
}
