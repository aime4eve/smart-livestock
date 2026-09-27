package com.smartlivestock.ranch.application.signal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.ranch.infrastructure.persistence.SignalEventOutboxJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Records entity change hints in the caller's transaction. Signal API remains
 * the authoritative state source; this outbox never carries rendered state.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SignalEventOutboxService {

    private final SignalEventOutboxJpaRepository outboxRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public void record(Long farmId, SignalEventType eventType, String entityType, Long entityId) {
        validate(farmId, eventType, entityType, entityId);
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("farmId", farmId);
        payload.put("entityType", entityType);
        payload.put("entityId", entityId);
        outboxRepository.upsertPending(
                farmId,
                eventType.name(),
                entityType,
                entityId,
                toJson(payload)
        );
    }

    private void validate(Long farmId, SignalEventType eventType, String entityType, Long entityId) {
        if (farmId == null || farmId <= 0) {
            throw new IllegalArgumentException("Signal event farmId is required");
        }
        if (eventType == null) {
            throw new IllegalArgumentException("Signal event type is required");
        }
        if (entityType == null || entityType.isBlank()) {
            throw new IllegalArgumentException("Signal event entity type is required");
        }
        if (entityId == null || entityId <= 0) {
            throw new IllegalArgumentException("Signal event entity id is required");
        }
    }

    private String toJson(Map<String, Object> payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (Exception e) {
            throw new IllegalStateException("Could not serialize signal outbox payload", e);
        }
    }
}
