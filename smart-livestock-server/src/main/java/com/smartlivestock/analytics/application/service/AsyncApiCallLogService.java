package com.smartlivestock.analytics.application.service;

import com.smartlivestock.analytics.domain.model.ApiCallLog;
import com.smartlivestock.analytics.domain.repository.ApiCallLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AsyncApiCallLogService {

    private final ApiCallLogRepository apiCallLogRepository;

    @Async
    public void logAsync(ApiCallLog callLog) {
        try {
            apiCallLogRepository.save(callLog);
        } catch (Exception e) {
            log.warn("Failed to persist API call log: {}", e.getMessage());
        }
    }
}
