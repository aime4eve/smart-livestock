package com.smartlivestock.analytics.application.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.domain.repository.ApiCallLogRepository;
import com.smartlivestock.analytics.domain.repository.ApiUsageDailyRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for UsageAggregationService covering the NIX-439 fix:
 * valid JSON in top_endpoints, idempotent re-runs, per-key failure isolation.
 */
class UsageAggregationServiceTest {

    private ApiCallLogRepository callLogRepository;
    private ApiUsageDailyRepository usageDailyRepository;
    private UsageAggregationService service;

    private static final LocalDate DATE = LocalDate.of(2026, 11, 26);

    @BeforeEach
    void setUp() {
        callLogRepository = mock(ApiCallLogRepository.class);
        usageDailyRepository = mock(ApiUsageDailyRepository.class);
        service = new UsageAggregationService(callLogRepository, usageDailyRepository);
        when(usageDailyRepository.findAllByUsageDateBetween(any(), any())).thenReturn(List.of());
    }

    private ApiCallLog callLog(long apiKeyId, long tenantId, String endpoint, int status, int ms) {
        ApiCallLog l = new ApiCallLog();
        l.setApiKeyId(apiKeyId);
        l.setTenantId(tenantId);
        l.setEndpoint(endpoint);
        l.setMethod("GET");
        l.setStatusCode(status);
        l.setResponseTimeMs(ms);
        l.setRequestedAt(Instant.now());
        return l;
    }

    @Test
    void writesTopEndpointsAsValidJson() throws Exception {
        when(callLogRepository.findAllByRequestedAtBetween(any(), any())).thenReturn(List.of(
                callLog(1, 10, "/api/v1/farms/{id}/livestock", 200, 100),
                callLog(1, 10, "/api/v1/farms/{id}/livestock", 200, 200),
                callLog(1, 10, "/api/v1/devices", 500, 50)
        ));

        service.aggregateForDate(DATE);

        ArgumentCaptor<ApiUsageDaily> captor = ArgumentCaptor.forClass(ApiUsageDaily.class);
        verify(usageDailyRepository).save(captor.capture());
        ApiUsageDaily saved = captor.getValue();

        JsonNode json = new ObjectMapper().readTree(saved.getTopEndpoints());
        assertTrue(json.isObject(), "topEndpoints must be a JSON object, not Map.toString()");
        assertEquals(2, json.get("/api/v1/farms/{id}/livestock").asInt());
        assertEquals(1, json.get("/api/v1/devices").asInt());
        assertEquals(3, saved.getTotalCalls());
        assertEquals(2, saved.getSuccessCalls());
        assertEquals(1, saved.getErrorCalls());
    }

    @Test
    void rerunForSameDateUpdatesExistingRowInsteadOfInsert() {
        ApiUsageDaily existing = new ApiUsageDaily();
        existing.setId(5L);
        existing.setApiKeyId(1L);
        existing.setTenantId(10L);
        existing.setUsageDate(DATE);
        when(usageDailyRepository.findAllByUsageDateBetween(any(), any())).thenReturn(List.of(existing));
        when(callLogRepository.findAllByRequestedAtBetween(any(), any()))
                .thenReturn(List.of(callLog(1, 10, "/api/v1/devices", 200, 100)));

        service.aggregateForDate(DATE);

        ArgumentCaptor<ApiUsageDaily> captor = ArgumentCaptor.forClass(ApiUsageDaily.class);
        verify(usageDailyRepository).save(captor.capture());
        assertEquals(5L, captor.getValue().getId(), "must reuse existing row id (UPDATE, not INSERT)");
        assertEquals(1, captor.getValue().getTotalCalls());
    }

    @Test
    void perKeyFailureDoesNotAbortWholeDay() {
        when(callLogRepository.findAllByRequestedAtBetween(any(), any())).thenReturn(List.of(
                callLog(1, 10, "/api/v1/devices", 200, 100),
                callLog(2, 10, "/api/v1/devices", 200, 100)
        ));
        when(usageDailyRepository.save(any()))
                .thenThrow(new RuntimeException("db down"))
                .thenAnswer(inv -> inv.getArgument(0));

        service.aggregateForDate(DATE);

        verify(usageDailyRepository, times(2)).save(any(ApiUsageDaily.class));
    }

    @Test
    void skipsWhenNoLogsForDate() {
        when(callLogRepository.findAllByRequestedAtBetween(any(), any())).thenReturn(List.of());

        service.aggregateForDate(DATE);

        verify(usageDailyRepository, never()).save(any(ApiUsageDaily.class));
    }
}
