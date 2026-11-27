package com.smartlivestock.analytics.application.service;

import com.smartlivestock.analytics.application.dto.UsageTrendDto;
import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.domain.repository.ApiUsageDailyRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for AnalyticsApplicationService, covering the getGlobalTrend fix:
 * avg response time must be call-volume weighted, not totalCalls/row-count.
 */
class AnalyticsApplicationServiceTest {

    private ApiUsageDailyRepository usageDailyRepository;
    private AnalyticsApplicationService service;

    private static final LocalDate D1 = LocalDate.of(2026, 11, 25);
    private static final LocalDate D2 = LocalDate.of(2026, 11, 26);

    @BeforeEach
    void setUp() {
        usageDailyRepository = mock(ApiUsageDailyRepository.class);
        service = new AnalyticsApplicationService(usageDailyRepository);
    }

    private ApiUsageDaily daily(Long apiKeyId, LocalDate date, int totalCalls,
                                int successCalls, int errorCalls, Integer avgMs) {
        ApiUsageDaily d = new ApiUsageDaily();
        d.setApiKeyId(apiKeyId);
        d.setTenantId(10L);
        d.setUsageDate(date);
        d.setTotalCalls(totalCalls);
        d.setSuccessCalls(successCalls);
        d.setErrorCalls(errorCalls);
        d.setAvgResponseMs(avgMs);
        return d;
    }

    @Test
    void globalTrendAveragesResponseTimeWeightedByCallVolume() {
        // Key A: 100 calls @ 10ms, Key B: 900 calls @ 2ms → weighted avg = 2ms (not 1000/2=500)
        when(usageDailyRepository.findAllByUsageDateBetween(any(), any())).thenReturn(List.of(
                daily(1L, D1, 100, 100, 0, 10),
                daily(2L, D1, 900, 900, 0, 2)
        ));

        List<UsageTrendDto> trend = service.getGlobalTrend(D1, D1);

        assertEquals(1, trend.size());
        assertEquals(1000, trend.get(0).getTotalCalls());
        assertEquals(1000, trend.get(0).getSuccessCalls());
        assertEquals(0, trend.get(0).getErrorCalls());
        assertEquals(2, trend.get(0).getAvgResponseMs());
    }

    @Test
    void globalTrendReturnsDatesAscendingAndHandlesNullAvg() {
        when(usageDailyRepository.findAllByUsageDateBetween(any(), any())).thenReturn(List.of(
                daily(1L, D2, 10, 9, 1, null),
                daily(1L, D1, 10, 10, 0, 5)
        ));

        List<UsageTrendDto> trend = service.getGlobalTrend(D1, D2);

        assertEquals(2, trend.size());
        assertEquals(D1, trend.get(0).getDate());
        assertEquals(5, trend.get(0).getAvgResponseMs());
        assertEquals(D2, trend.get(1).getDate());
        assertEquals(0, trend.get(1).getAvgResponseMs(), "null avgResponseMs must not NPE, falls back to 0");
    }

    @Test
    void tenantTrendPassesThroughStoredValues() {
        when(usageDailyRepository.findByTenantIdAndUsageDateBetween(10L, D1, D1))
                .thenReturn(List.of(daily(3L, D1, 1440, 1440, 0, 1)));

        List<UsageTrendDto> trend = service.getTenantTrend(10L, D1, D1);

        assertEquals(1, trend.size());
        assertEquals(1440, trend.get(0).getTotalCalls());
        assertEquals(1, trend.get(0).getAvgResponseMs());
    }
}
