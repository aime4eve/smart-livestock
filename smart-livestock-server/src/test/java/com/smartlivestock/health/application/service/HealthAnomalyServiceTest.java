package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.smartlivestock.health.application.port.AnomalyScoreClient.AnomalyPrediction;
import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.cache.RedisCacheService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class HealthAnomalyServiceTest {

    @Mock private AnomalyScoreClient anomalyScoreClient;
    @Mock private AnomalyScoreRepository anomalyScoreRepo;
    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private RedisCacheService redis;

    @InjectMocks
    private HealthAnomalyService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "alertThreshold", 0.7);
        ReflectionTestUtils.setField(service, "dedupTtlMinutes", 60);
    }

    @Test
    void highScore_writesScore_updatesSnapshot_raisesAlert() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(new AnomalyPrediction(
                        100L, 0.85, "multivariate",
                        0.2, 0.3, 0.5,
                        "health_l1", 50, "{}")));
        HealthSnapshot snap = new HealthSnapshot();
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(snap));

        service.assess(1L, 1L, 100L);

        verify(anomalyScoreRepo).save(any(AnomalyScore.class));
        verify(snapshotRepo).save(any(HealthSnapshot.class));
        verify(ranchCommandPort).createAlert(any(AlertInfo.class));
        verify(redis).set(eq("ai:dedup:100"), eq("1"), any(Duration.class));
    }

    @Test
    void aiPlatformUnavailable_degradesSilently() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(anomalyScoreClient.analyze(anyLong(), anyLong(), anyList(), anyInt()))
                .thenReturn(List.of());

        service.assess(1L, 1L, 100L);

        verify(anomalyScoreRepo, never()).save(any());
        verify(snapshotRepo, never()).save(any());
        verify(ranchCommandPort, never()).createAlert(any());
        verify(redis, never()).set(anyString(), anyString(), any(Duration.class));
    }

    @Test
    void dedupHit_skipsEverything() {
        when(redis.get("ai:dedup:100")).thenReturn("1");

        service.assess(1L, 1L, 100L);

        verify(anomalyScoreClient, never()).analyze(anyLong(), anyLong(), anyList(), anyInt());
        verify(anomalyScoreRepo, never()).save(any());
    }

    @Test
    void lowScore_noAlert() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(new AnomalyPrediction(
                        100L, 0.15, "normal",
                        0.05, 0.05, 0.05,
                        "health_l1", 50, "{}")));
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(new HealthSnapshot()));

        service.assess(1L, 1L, 100L);

        verify(anomalyScoreRepo).save(any(AnomalyScore.class));
        verify(ranchCommandPort, never()).createAlert(any());
    }
}
