package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.dto.OpenTelemetryDtos.LivestockTelemetry;
import com.smartlivestock.health.domain.model.ActivityLog;
import com.smartlivestock.health.domain.model.RumenMotilityLog;
import com.smartlivestock.shared.domain.TelemetryPage;
import com.smartlivestock.health.domain.model.TemperatureLog;
import com.smartlivestock.health.domain.repository.ActivityLogRepository;
import com.smartlivestock.health.domain.repository.RumenMotilityLogRepository;
import com.smartlivestock.health.domain.repository.TemperatureLogRepository;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the health-side Open telemetry query service (NIX-323):
 * type filtering and empty-series semantics.
 */
@ExtendWith(MockitoExtension.class)
class OpenTelemetryQueryServiceTest {

    private static final Long LIVESTOCK_ID = 101L;
    private static final Long DEVICE_ID = 62L;
    private static final Instant FROM = Instant.parse("2026-10-19T00:00:00Z");
    private static final Instant TO = Instant.parse("2026-10-26T00:00:00Z");

    @Mock
    private TemperatureLogRepository temperatureLogRepository;
    @Mock
    private RumenMotilityLogRepository motilityLogRepository;
    @Mock
    private ActivityLogRepository activityLogRepository;

    private OpenTelemetryQueryService createService() {
        return new OpenTelemetryQueryService(temperatureLogRepository, motilityLogRepository, activityLogRepository);
    }

    @Test
    void nullTypesQueriesAllSeries() {
        when(temperatureLogRepository.findPageByLivestock(any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(), 1, 100, 0));
        when(motilityLogRepository.findPageByLivestock(any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(), 1, 100, 0));
        when(activityLogRepository.findPageByLivestock(any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(), 1, 100, 0));

        LivestockTelemetry result = createService().queryByLivestock(
                LIVESTOCK_ID, DEVICE_ID, null, FROM, TO, 1, 100);

        verify(temperatureLogRepository).findPageByLivestock(LIVESTOCK_ID, FROM, TO, 1, 100);
        verify(motilityLogRepository).findPageByLivestock(LIVESTOCK_ID, FROM, TO, 1, 100);
        verify(activityLogRepository).findPageByLivestock(LIVESTOCK_ID, FROM, TO, 1, 100);
        assertThat(result.temperature().total()).isZero();
        assertThat(result.motility().total()).isZero();
        assertThat(result.activity().total()).isZero();
    }

    @Test
    void temperatureOnlySkipsMotilityAndActivityRepositories() {
        when(temperatureLogRepository.findPageByLivestock(any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(new TemperatureLog()), 1, 100, 1));

        LivestockTelemetry result = createService().queryByLivestock(
                LIVESTOCK_ID, DEVICE_ID, Set.of("temperature"), FROM, TO, 1, 100);

        verify(temperatureLogRepository).findPageByLivestock(LIVESTOCK_ID, FROM, TO, 1, 100);
        verify(motilityLogRepository, never()).findPageByLivestock(any(), any(), any(), anyInt(), anyInt());
        verify(activityLogRepository, never()).findPageByLivestock(any(), any(), any(), anyInt(), anyInt());
        assertThat(result.temperature().total()).isEqualTo(1);
        assertThat(result.motility().total()).isZero();
        assertThat(result.activity().total()).isZero();
    }

    @Test
    void unknownTypeYieldsAllEmptySeries() {
        LivestockTelemetry result = createService().queryByLivestock(
                LIVESTOCK_ID, DEVICE_ID, Set.of("nope"), FROM, TO, 1, 100);

        assertThat(result.temperature().total()).isZero();
        assertThat(result.motility().total()).isZero();
        assertThat(result.activity().total()).isZero();
    }

    @Test
    void deviceQuerySupportsBothSeries() {
        when(temperatureLogRepository.findPageByDevice(eq(DEVICE_ID), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(), 1, 100, 0));
        when(motilityLogRepository.findPageByDevice(eq(DEVICE_ID), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(new RumenMotilityLog()), 1, 100, 1));

        var result = createService().queryByDevice(DEVICE_ID, null, FROM, TO, 1, 100);

        verify(activityLogRepository, never()).findPageByLivestock(any(), any(), any(), anyInt(), anyInt());
        assertThat(result.temperature().total()).isZero();
        assertThat(result.motility().total()).isEqualTo(1);
        assertThat(result.deviceId()).isEqualTo(DEVICE_ID);
    }

    @Test
    void activityReadingsMapDomainFields() {
        ActivityLog log = new ActivityLog();
        when(activityLogRepository.findPageByLivestock(any(), any(), any(), anyInt(), anyInt()))
                .thenReturn(new TelemetryPage<>(List.of(log), 1, 100, 1));

        LivestockTelemetry result = createService().queryByLivestock(
                LIVESTOCK_ID, DEVICE_ID, Set.of("activity"), FROM, TO, 1, 100);

        assertThat(result.activity().items()).hasSize(1);
    }
}
