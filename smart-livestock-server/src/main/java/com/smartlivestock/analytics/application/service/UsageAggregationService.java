package com.smartlivestock.analytics.application.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.domain.repository.ApiCallLogRepository;
import com.smartlivestock.analytics.domain.repository.ApiUsageDailyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UsageAggregationService {

    // Serializes top-endpoint stats as real JSON: api_usage_daily.top_endpoints is a
    // JSONB column and Map.toString() output ({/api/x=1, ...}) is rejected by PG (NIX-439).
    private static final ObjectMapper TOP_ENDPOINTS_MAPPER = new ObjectMapper();

    private final ApiCallLogRepository callLogRepository;
    private final ApiUsageDailyRepository usageDailyRepository;

    /**
     * Daily aggregation: runs at 00:05 UTC, aggregates previous day's call logs
     * into api_usage_daily grouped by apiKeyId.
     */
    @Scheduled(cron = "0 5 0 * * *")
    public void aggregateDailyUsage() {
        LocalDate yesterday = LocalDate.now(ZoneOffset.UTC).minusDays(1);
        aggregateForDate(yesterday);
    }

    public void aggregateForDate(LocalDate date) {
        Instant from = date.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant to = date.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();

        List<ApiCallLog> logs = callLogRepository.findAllByRequestedAtBetween(from, to);
        if (logs.isEmpty()) {
            log.info("No API call logs found for date={}, skipping aggregation", date);
            return;
        }

        // Group by apiKeyId
        Map<Long, List<ApiCallLog>> byKey = logs.stream()
                .filter(l -> l.getApiKeyId() != null)
                .collect(Collectors.groupingBy(ApiCallLog::getApiKeyId));

        // Load existing rows for this date so re-runs/backfills UPDATE in place
        // instead of violating UNIQUE(api_key_id, usage_date) (NIX-439).
        Map<Long, ApiUsageDaily> existingByKey = new HashMap<>();
        for (ApiUsageDaily existing : usageDailyRepository.findAllByUsageDateBetween(date, date)) {
            existingByKey.put(existing.getApiKeyId(), existing);
        }

        int count = 0;
        int failed = 0;
        for (Map.Entry<Long, List<ApiCallLog>> entry : byKey.entrySet()) {
            // Isolate per-key failures: one bad key must not abort the whole day
            try {
                List<ApiCallLog> keyLogs = entry.getValue();
                ApiCallLog first = keyLogs.get(0);

                int totalCalls = keyLogs.size();
                int successCalls = (int) keyLogs.stream().filter(l -> l.getStatusCode() < 400).count();
                int errorCalls = totalCalls - successCalls;
                double avgMs = keyLogs.stream()
                        .filter(l -> l.getResponseTimeMs() != null)
                        .mapToInt(ApiCallLog::getResponseTimeMs)
                        .average().orElse(0.0);

                // P95
                List<Integer> responseTimes = keyLogs.stream()
                        .filter(l -> l.getResponseTimeMs() != null)
                        .mapToInt(ApiCallLog::getResponseTimeMs)
                        .sorted().boxed().toList();
                int p95 = responseTimes.isEmpty() ? 0
                        : responseTimes.get((int) Math.ceil(responseTimes.size() * 0.95) - 1);

                // Top endpoints (top 5), serialized as a real JSON object
                Map<String, Long> endpointCounts = new LinkedHashMap<>();
                keyLogs.stream()
                        .collect(Collectors.groupingBy(ApiCallLog::getEndpoint, Collectors.counting()))
                        .entrySet().stream()
                        .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                        .limit(5)
                        .forEach(e -> endpointCounts.put(e.getKey(), e.getValue()));
                String topEndpoints = writeTopEndpointsJson(endpointCounts);

                ApiUsageDaily daily = existingByKey.getOrDefault(entry.getKey(), new ApiUsageDaily());
                daily.setApiKeyId(entry.getKey());
                daily.setTenantId(first.getTenantId());
                daily.setUsageDate(date);
                daily.setTotalCalls(totalCalls);
                daily.setSuccessCalls(successCalls);
                daily.setErrorCalls(errorCalls);
                daily.setAvgResponseMs((int) avgMs);
                daily.setP95ResponseMs(p95);
                daily.setTopEndpoints(topEndpoints);

                usageDailyRepository.save(daily);
                count++;
            } catch (Exception e) {
                failed++;
                log.warn("Failed to aggregate usage for apiKeyId={} on date={}: {}",
                        entry.getKey(), date, e.getMessage());
            }
        }

        log.info("Aggregated {} API keys for date={}, total logs={}, failed={}",
                count, date, logs.size(), failed);
    }

    private String writeTopEndpointsJson(Map<String, Long> endpointCounts) {
        try {
            return TOP_ENDPOINTS_MAPPER.writeValueAsString(endpointCounts);
        } catch (JsonProcessingException e) {
            // Never fail the whole aggregation on serialization: fall back to '{}'
            log.warn("Failed to serialize top endpoints as JSON: {}", e.getMessage());
            return "{}";
        }
    }

    /**
     * Clean up call logs older than 90 days.
     */
    @Scheduled(cron = "0 30 1 * * *")
    @Transactional
    public void cleanupOldLogs() {
        Instant cutoff = Instant.now().minusSeconds(90L * 24 * 60 * 60);
        log.info("Cleaning up API call logs older than {}", cutoff);
        callLogRepository.deleteOlderThan(cutoff);
    }
}
