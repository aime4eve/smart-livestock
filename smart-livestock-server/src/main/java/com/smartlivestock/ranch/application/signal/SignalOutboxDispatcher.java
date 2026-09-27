package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.infrastructure.persistence.SignalEventOutboxJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class SignalOutboxDispatcher {

    private static final int MAX_ERROR_LENGTH = 2_000;

    private final SignalEventOutboxJpaRepository outboxRepository;
    private final SignalOutboxEventPublisher eventPublisher;

    @Value("${signal.outbox.batch-size:100}")
    private int batchSize = 100;

    @Value("${signal.outbox.max-retries:5}")
    private int maxRetries = 5;

    @Value("${signal.outbox.retry-backoff:PT5S}")
    private Duration retryBackoff = Duration.ofSeconds(5);

    @Value("${signal.outbox.max-backoff:PT5M}")
    private Duration maxBackoff = Duration.ofMinutes(5);

    @Scheduled(fixedDelayString = "${signal.outbox.poll-ms:1000}")
    public void dispatchScheduled() {
        int dispatched;
        do {
            dispatched = dispatchDueBatch();
        } while (dispatched == batchSize);
    }

    @Transactional
    public int dispatchDueBatch() {
        List<Long> ids = outboxRepository.findDispatchableIds(batchSize);
        if (ids.isEmpty()) return 0;

        List<SignalEventOutboxJpaEntity> events = outboxRepository.findAllById(ids)
                .stream()
                .sorted(Comparator.comparing(SignalEventOutboxJpaEntity::getId))
                .toList();
        for (SignalEventOutboxJpaEntity event : events) {
            try {
                eventPublisher.publish(event);
                event.setStatus("DISPATCHED");
                event.setDispatchedAt(Instant.now());
                event.setLastError(null);
            } catch (Exception e) {
                markRetry(event, e);
            }
        }
        return events.size();
    }

    @Transactional
    public List<Long> claimDueIds(int limit) {
        return outboxRepository.findDispatchableIds(limit);
    }

    private void markRetry(SignalEventOutboxJpaEntity event, Exception error) {
        event.setRetryCount(event.getRetryCount() + 1);
        event.setLastError(truncate(error.getMessage() == null
                ? error.getClass().getSimpleName() : error.getMessage()));
        if (event.getRetryCount() >= maxRetries) {
            event.setStatus("FAILED");
            log.warn("Signal outbox event [{}] failed after {} attempts",
                    event.getId(), event.getRetryCount(), error);
            return;
        }

        event.setStatus("PENDING");
        event.setAvailableAt(Instant.now().plus(backoffFor(event.getRetryCount())));
        log.warn("Signal outbox event [{}] dispatch failed; retry {} at {}",
                event.getId(), event.getRetryCount(), event.getAvailableAt(), error);
    }

    private Duration backoffFor(int retryCount) {
        long multiplier = 1L << Math.min(retryCount - 1, 16);
        Duration backoff = retryBackoff.multipliedBy(multiplier);
        return backoff.compareTo(maxBackoff) > 0 ? maxBackoff : backoff;
    }

    private String truncate(String value) {
        return value.length() <= MAX_ERROR_LENGTH
                ? value : value.substring(0, MAX_ERROR_LENGTH);
    }
}
