package com.smartlivestock.analytics.application.service;

import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.analytics.domain.model.ApiUsageDaily;
import com.smartlivestock.analytics.domain.repository.ApiCallLogRepository;
import com.smartlivestock.analytics.domain.repository.ApiUsageDailyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class UsageAggregationService {

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

        int count = 0;
        for (Map.Entry<Long, List<ApiCallLog>> entry : byKey.entrySet()) {
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

            // Top endpoints (top 5)
            String topEndpoints = keyLogs.stream()
                    .collect(Collectors.groupingBy(ApiCallLog::getEndpoint, Collectors.counting()))
                    .entrySet().stream()
                    .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                    .limit(5)
                    .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue))
                    .toString();

            ApiUsageDaily daily = new ApiUsageDaily();
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
        }

        log.info("Aggregated {} API keys for date={}, total logs={}", count, date, logs.size());
    }

    /**
     * Clean up call logs older than 90 days.
     */
    @Scheduled(cron = "0 30 1 * * *")
    public void cleanupOldLogs() {
        Instant cutoff = Instant.now().minusSeconds(90L * 24 * 60 * 60);
        log.info("Cleaning up API call logs older than {}", cutoff);
        callLogRepository.deleteOlderThan(cutoff);
    }
}
