package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledFuture;

@Slf4j
@Service
public class SignalStreamNotificationService {

    private final SignalRevisionService revisionService;
    private final Broadcaster broadcaster;
    private final Clock clock;
    private final ThrottleScheduler scheduler;
    private final Duration minWindow;
    private final Duration maxDelay;
    private final Map<Long, PendingBatch> batches = new ConcurrentHashMap<>();

    public SignalStreamNotificationService(
            SignalRevisionService revisionService,
            Broadcaster broadcaster,
            Clock clock,
            ThrottleScheduler scheduler,
            @Value("${signal.stream.min-merge-window:PT1S}") Duration minWindow,
            @Value("${signal.stream.max-delay:PT5S}") Duration maxDelay
    ) {
        this.revisionService = revisionService;
        this.broadcaster = broadcaster;
        this.clock = clock;
        this.scheduler = scheduler;
        this.minWindow = minWindow;
        this.maxDelay = maxDelay;
    }

    public void accept(SignalEventOutboxJpaEntity event) {
        if (!broadcaster.hasSubscribers(event.getFarmId())) {
            batches.remove(event.getFarmId());
            return;
        }

        Instant now = clock.instant();
        PendingBatch batch = batches.compute(event.getFarmId(), (farmId, existing) -> {
            if (existing == null) return new PendingBatch(now, now.plus(maxDelay));
            existing.merge(event);
            return existing;
        });
        synchronized (batch) {
            batch.merge(event);
            scheduleIfMissing(event.getFarmId(), batch, now);
        }
    }

    private void scheduleIfMissing(Long farmId, PendingBatch batch, Instant now) {
        if (batch.scheduledFuture != null) return;

        Instant readyAt = batch.firstEventAt.plus(minWindow);
        Duration delay = Duration.between(now, readyAt);
        if (delay.isNegative()) delay = Duration.ZERO;
        batch.scheduledFuture = new CompletedScheduledFuture(
                scheduler.schedule(() -> flushIfDue(farmId), delay)
        );
    }

    void flushIfDue(Long farmId) {
        PendingBatch batch = batches.get(farmId);
        if (batch == null) return;

        synchronized (batch) {
            Instant now = clock.instant();
            if (now.isBefore(batch.firstEventAt.plus(minWindow))
                    && now.isBefore(batch.deadline)) {
                scheduleIfMissing(farmId, batch, now);
                return;
            }
            batches.remove(farmId, batch);
            batch.scheduledFuture = null;
        }

        try {
            FarmSignalRevision revision = revisionService.ensureFarm(farmId);
            broadcaster.broadcast(new SignalStreamNotification(
                    farmId,
                    List.copyOf(batch.livestockIds),
                    List.copyOf(batch.fenceIds),
                    revision.statusRevision(),
                    revision.positionRevision(),
                    revision.fenceGeometryRevision()
            ));
        } catch (Exception e) {
            log.warn("Failed to broadcast signal stream batch for farm {}", farmId, e);
        }
    }

    public interface Broadcaster {
        boolean hasSubscribers(Long farmId);
        void broadcast(SignalStreamNotification notification);
    }

    public interface ThrottleScheduler {
        Runnable schedule(Runnable command, Duration delay);
    }

    private static final class PendingBatch {
        private final Instant firstEventAt;
        private final Instant deadline;
        private final Set<Long> livestockIds = new LinkedHashSet<>();
        private final Set<Long> fenceIds = new LinkedHashSet<>();
        private ScheduledFuture<?> scheduledFuture;
        private PendingBatch(Instant firstEventAt, Instant deadline) {
            this.firstEventAt = firstEventAt;
            this.deadline = deadline;
        }

        private void merge(SignalEventOutboxJpaEntity event) {
            SignalEventType eventType;
            try {
                eventType = SignalEventType.valueOf(event.getEventType());
            } catch (IllegalArgumentException ignored) {
                return;
            }
            if (eventType == SignalEventType.LIVESTOCK_POSITION_CHANGED
                    || eventType == SignalEventType.RUMEN_METRIC_CHANGED
                    || "LIVESTOCK".equals(event.getEntityType())) {
                livestockIds.add(event.getEntityId());
            }
            if ("FENCE".equals(event.getEntityType())) {
                fenceIds.add(event.getEntityId());
            }
        }
    }

    private record CompletedScheduledFuture(Runnable command)
            implements ScheduledFuture<Object> {
        @Override public boolean cancel(boolean mayInterruptIfRunning) { return false; }
        @Override public boolean isCancelled() { return false; }
        @Override public boolean isDone() { return true; }
        @Override public Object get() { return null; }
        @Override public Object get(long timeout, java.util.concurrent.TimeUnit unit) { return null; }
        @Override public long getDelay(java.util.concurrent.TimeUnit unit) { return 0; }
        @Override public int compareTo(java.util.concurrent.Delayed other) { return 0; }
    }
}
