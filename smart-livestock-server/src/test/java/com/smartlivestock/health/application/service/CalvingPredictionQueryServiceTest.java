package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.HealthDtos.CalvingPredictionListResponse;
import com.smartlivestock.health.domain.model.CalvingPrediction;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.port.HealthSubscriptionPort;
import com.smartlivestock.health.domain.port.RanchQueryPort;
import com.smartlivestock.health.domain.port.dto.LivestockInfo;
import com.smartlivestock.health.domain.repository.CalvingPredictionRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Read-side behaviour of the NIX-389 calving prediction list: gate
 * rejection, latest-row-per-livestock sourcing, snapshot-score filtering and
 * ordering.
 */
@ExtendWith(MockitoExtension.class)
class CalvingPredictionQueryServiceTest {

    @Mock
    private CalvingPredictionRepository predictionRepo;
    @Mock
    private HealthSnapshotRepository snapshotRepo;
    @Mock
    private HealthSubscriptionPort subscriptionPort;
    @Mock
    private RanchQueryPort ranchQueryPort;

    private CalvingPredictionQueryService service;

    @BeforeEach
    void setUp() {
        service = new CalvingPredictionQueryService(
                predictionRepo, snapshotRepo, subscriptionPort, ranchQueryPort);
    }

    private CalvingPrediction row(long livestockId, int riskScore) {
        CalvingPrediction row = new CalvingPrediction();
        row.setFarmId(1L);
        row.setLivestockId(livestockId);
        row.setRiskScore(riskScore);
        row.setPredictedAt(Instant.parse("2026-11-07T00:00:00Z"));
        row.setExpectedWindowStart(Instant.parse("2026-11-08T00:00:00Z"));
        row.setExpectedWindowEnd(Instant.parse("2026-11-09T00:00:00Z"));
        row.setTempDropCelsius(new BigDecimal("1.20"));
        row.setActivityRatio(new BigDecimal("0.80"));
        row.setPriorEnabled(Boolean.TRUE);
        return row;
    }

    private HealthSnapshot snapshot(long livestockId, Integer calvingRiskScore) {
        HealthSnapshot snapshot = new HealthSnapshot();
        snapshot.setLivestockId(livestockId);
        snapshot.setFarmId(1L);
        snapshot.setCalvingRiskScore(calvingRiskScore);
        return snapshot;
    }

    @Test
    @DisplayName("locked calving_warning gate rejects with 403 and never queries data")
    void gateLocked_rejected() {
        when(subscriptionPort.hasFeature(CalvingPredictionQueryService.FEATURE_KEY)).thenReturn(false);

        assertThatThrownBy(() -> service.getCalvingPredictions(1L, 200))
                .isInstanceOfSatisfying(ApiException.class,
                        e -> assertThat(e.getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN));

        verify(predictionRepo, never()).findLatestPerLivestockByFarm(anyLong(), anyInt());
    }

    @Test
    @DisplayName("lists the latest row per livestock with codes, clamped limit and risk-desc order")
    void list_sourcingAndOrdering() {
        when(subscriptionPort.hasFeature(CalvingPredictionQueryService.FEATURE_KEY)).thenReturn(true);
        when(predictionRepo.findLatestPerLivestockByFarm(1L, 200)).thenReturn(
                List.of(row(1L, 60), row(2L, 75)));
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(1L, 60), snapshot(2L, 75)));
        when(ranchQueryPort.findLivestockById(1L))
                .thenReturn(Optional.of(new LivestockInfo(1L, 1L, "SL-001", "F", "Holstein")));
        when(ranchQueryPort.findLivestockById(2L))
                .thenReturn(Optional.of(new LivestockInfo(2L, 1L, "SL-002", "F", "Holstein")));

        // limit above MAX is clamped to 500, below 1 clamped to 1
        assertThat(CalvingPredictionQueryService.clampLimit(9999)).isEqualTo(500);
        assertThat(CalvingPredictionQueryService.clampLimit(0)).isEqualTo(1);
        assertThat(CalvingPredictionQueryService.clampLimit(200)).isEqualTo(200);

        CalvingPredictionListResponse response = service.getCalvingPredictions(1L, 200);

        verify(predictionRepo).findLatestPerLivestockByFarm(1L, 200);
        assertThat(response.items()).hasSize(2);
        // Highest risk first regardless of the row order returned by the repo.
        assertThat(response.items().get(0).livestockCode()).isEqualTo("SL-002");
        assertThat(response.items().get(0).riskScore()).isEqualTo(75);
        assertThat(response.items().get(1).livestockId()).isEqualTo("1");
        assertThat(response.items().get(1).riskScore()).isEqualTo(60);
        // DTO carries the prediction evidence but no baseline audit columns.
        assertThat(response.items().get(0).tempDropCelsius()).isEqualByComparingTo("1.20");
        assertThat(response.items().get(0).activityRatio()).isEqualByComparingTo("0.80");
        assertThat(response.items().get(0).priorEnabled()).isTrue();
    }

    @Test
    @DisplayName("snapshot score floor: >=50 listed, <50 and snapshot-less heads dropped")
    void list_snapshotScoreFloor() {
        when(subscriptionPort.hasFeature(CalvingPredictionQueryService.FEATURE_KEY)).thenReturn(true);
        // Repo returns a row for every head it has history for.
        when(predictionRepo.findLatestPerLivestockByFarm(1L, 200)).thenReturn(List.of(
                row(1L, 70),   // snapshot 70 -> alert band, listed
                row(2L, 55),   // snapshot 55 -> watch band, listed
                row(3L, 65),   // snapshot 49 -> below floor, dropped
                row(4L, 90))); // no snapshot row -> dropped
        when(snapshotRepo.findByFarmId(1L)).thenReturn(List.of(
                snapshot(1L, 70), snapshot(2L, 55), snapshot(3L, 49)));

        CalvingPredictionListResponse response = service.getCalvingPredictions(1L, 200);

        assertThat(response.items()).extracting("livestockId")
                .containsExactly("1", "2");
    }
}
