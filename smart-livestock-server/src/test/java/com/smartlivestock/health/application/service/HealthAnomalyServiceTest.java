package com.smartlivestock.health.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.smartlivestock.health.application.port.AnomalyScoreClient.AnomalyPrediction;
import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.cache.RedisCacheService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class HealthAnomalyServiceTest {

    @Mock private AnomalyScoreClient anomalyScoreClient;
    @Mock private AnomalyScoreRepository anomalyScoreRepo;
    @Mock private HealthSnapshotRepository snapshotRepo;
    @Mock private RanchCommandPort ranchCommandPort;
    @Mock private RanchQueryPort ranchQueryPort;
    @Mock private RedisCacheService redis;
    @Spy private ObjectMapper objectMapper = new ObjectMapper();
    @Mock private com.smartlivestock.ranch.application.signal.SignalRevisionService signalRevisionService;

    private HealthAnomalyService service;

    @BeforeEach
    void setUp() {
        service = new HealthAnomalyService(anomalyScoreClient, anomalyScoreRepo,
                snapshotRepo, ranchCommandPort, ranchQueryPort, redis, objectMapper,
                signalRevisionService);
        ReflectionTestUtils.setField(service, "alertThreshold", 0.7);
        ReflectionTestUtils.setField(service, "resolveThreshold", 0.5);
        ReflectionTestUtils.setField(service, "dedupTtlMinutes", 60);
    }

    private AnomalyPrediction pred(double score, String type) {
        return new AnomalyPrediction(100L, score, type, 0.2, 0.3, 0.5,
                "health_l1", 50, "{\"model_version\":\"l1-v1\"}");
    }

    @Test
    void highScore_writesScore_updatesSnapshot_raisesAiAlertOnce() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(ranchQueryPort.hasActiveAlert(100L, "AI_ANOMALY")).thenReturn(false);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(pred(0.85, "multivariate")));
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(new HealthSnapshot()));

        service.assess(1L, 1L, 100L);

        ArgumentCaptor<AnomalyScore> scoreCaptor = ArgumentCaptor.forClass(AnomalyScore.class);
        verify(anomalyScoreRepo).save(scoreCaptor.capture());
        assertThat(scoreCaptor.getValue().getModelMeta())
                .containsEntry("model_version", "l1-v1");
        verify(snapshotRepo).save(any(HealthSnapshot.class));

        ArgumentCaptor<AlertInfo> alertCaptor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort).createAlert(alertCaptor.capture());
        // alerts.source CHECK allows only RULE/AI/DATAGEN — telemetrySource must not leak in
        assertThat(alertCaptor.getValue().source()).isEqualTo("AI");
        assertThat(alertCaptor.getValue().alertType()).isEqualTo("AI_ANOMALY");
        assertThat(alertCaptor.getValue().severity()).isEqualTo("CRITICAL");
        verify(ranchCommandPort, never()).resolveAlertsBySource(anyLong(), anyString());
        verify(redis).set(eq("ai:dedup:100"), eq("1"), any(Duration.class));
    }

    @Test
    void activeAlertAlreadyExists_doesNotCreateDuplicate() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(ranchQueryPort.hasActiveAlert(100L, "AI_ANOMALY")).thenReturn(true);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(pred(0.85, "multivariate")));
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(new HealthSnapshot()));

        service.assess(1L, 1L, 100L);

        verify(anomalyScoreRepo).save(any(AnomalyScore.class));
        verify(ranchCommandPort, never()).createAlert(any());
        verify(redis).set(eq("ai:dedup:100"), eq("1"), any(Duration.class));
    }

    @Test
    void scoreBelowHysteresis_resolvesOnlyAiAlerts() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(pred(0.15, "normal")));
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(new HealthSnapshot()));

        service.assess(1L, 1L, 100L);

        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort).resolveAlertsBySource(100L, "AI");
        verify(redis).set(eq("ai:dedup:100"), eq("1"), any(Duration.class));
    }

    @Test
    void nearZeroScore_skipsRowButStillSyncsSnapshotAndDedup() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(pred(0.0005, "normal")));
        HealthSnapshot snap = new HealthSnapshot();
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(snap));

        service.assess(1L, 1L, 100L);

        verify(anomalyScoreRepo, never()).save(any());
        verify(snapshotRepo).save(snap);
        // recovered livestock clears its AI alerts so the overview stops counting it
        verify(ranchCommandPort).resolveAlertsBySource(100L, "AI");
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
    void abruptChangeMapsToTemperatureAbnormal() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(ranchQueryPort.hasActiveAlert(100L, "TEMPERATURE_ABNORMAL")).thenReturn(false);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(pred(0.75, "abrupt_change")));
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(new HealthSnapshot()));

        service.assess(1L, 1L, 100L, "THINGSBOARD");

        ArgumentCaptor<AlertInfo> alertCaptor = ArgumentCaptor.forClass(AlertInfo.class);
        verify(ranchCommandPort).createAlert(alertCaptor.capture());
        assertThat(alertCaptor.getValue().alertType()).isEqualTo("TEMPERATURE_ABNORMAL");
        assertThat(alertCaptor.getValue().severity()).isEqualTo("WARNING");
        // telemetry source must stay on the anomaly_scores row, never on the alert
        assertThat(alertCaptor.getValue().source()).isEqualTo("AI");
        verify(anomalyScoreRepo).save(argThat((AnomalyScore s) ->
                "THINGSBOARD".equals(s.getSource())));
    }

    @Test
    void midZoneBetweenAlertAndResolveThresholds_neitherCreatesNorResolves() {
        when(redis.get("ai:dedup:100")).thenReturn(null);
        when(anomalyScoreClient.analyze(1L, 1L, List.of(100L), 24))
                .thenReturn(List.of(pred(0.55, "multivariate")));
        when(snapshotRepo.findByLivestockId(100L)).thenReturn(Optional.of(new HealthSnapshot()));

        service.assess(1L, 1L, 100L);

        verify(ranchCommandPort, never()).createAlert(any());
        verify(ranchCommandPort, never()).resolveAlertsBySource(anyLong(), anyString());
        verify(redis).set(eq("ai:dedup:100"), eq("1"), any(Duration.class));
    }
}
