package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.application.signal.SignalRevisionService.FarmSignalRevision;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SignalStreamNotificationServiceTest {

    @Mock
    private SignalRevisionService revisionService;

    private Instant now;
    private MutableClock clock;
    private final List<SignalStreamNotification> broadcasts = new ArrayList<>();
    private final List<Runnable> scheduledCommands = new ArrayList<>();
    private SignalStreamNotificationService service;

    @BeforeEach
    void setUp() {
        now = Instant.parse("2026-09-28T00:00:00Z");
        clock = new MutableClock(now);
        var scheduler = new SignalStreamNotificationService.ThrottleScheduler() {
            @Override
            public Runnable schedule(Runnable command, Duration delay) {
                scheduledCommands.add(command);
                return command;
            }
        };

        service = new SignalStreamNotificationService(
                revisionService,
                new SignalStreamNotificationService.Broadcaster() {
                    @Override
                    public boolean hasSubscribers(Long farmId) {
                        return true;
                    }

                    @Override
                    public void broadcast(SignalStreamNotification notification) {
                        broadcasts.add(notification);
                    }
                },
                clock,
                scheduler,
                Duration.ofSeconds(1),
                Duration.ofSeconds(5)
        );
    }

    @Test
    void highFrequencyFarmEventsMergeIntoOneNotification() {
        when(revisionService.ensureFarm(1L)).thenReturn(revision(12L, 34L, 5L));

        service.accept(event(1L, SignalEventType.LIVESTOCK_POSITION_CHANGED, "LIVESTOCK", 14L));
        service.accept(event(1L, SignalEventType.RUMEN_METRIC_CHANGED, "LIVESTOCK", 15L));
        service.accept(event(1L, SignalEventType.FENCE_SIGNAL_CHANGED, "FENCE", 7L));

        assertThat(broadcasts).isEmpty();
        assertThat(scheduledCommands).hasSize(1);

        clock.advance(Duration.ofSeconds(1));
        scheduledCommands.getFirst().run();

        assertThat(broadcasts).hasSize(1);
        SignalStreamNotification notification = broadcasts.getFirst();
        assertThat(notification.livestockIds()).containsExactly(14L, 15L);
        assertThat(notification.fenceIds()).containsExactly(7L);
        assertThat(notification.statusRevision()).isEqualTo(12L);
        assertThat(notification.positionRevision()).isEqualTo(34L);
        assertThat(notification.fenceGeometryRevision()).isEqualTo(5L);
    }

    @Test
    void noSubscribersDoesNotReadRevisionsOrScheduleWork() {
        service = new SignalStreamNotificationService(
                revisionService,
                new SignalStreamNotificationService.Broadcaster() {
                    @Override
                    public boolean hasSubscribers(Long farmId) {
                        return false;
                    }

                    @Override
                    public void broadcast(SignalStreamNotification notification) {}
                },
                clock,
                (command, delay) -> command,
                Duration.ofSeconds(1),
                Duration.ofSeconds(5)
        );

        service.accept(event(1L, SignalEventType.LIVESTOCK_POSITION_CHANGED, "LIVESTOCK", 14L));

        assertThat(broadcasts).isEmpty();
        assertThat(scheduledCommands).isEmpty();
    }

    private SignalEventOutboxJpaEntity event(
            Long farmId, SignalEventType eventType, String entityType, Long entityId
    ) {
        SignalEventOutboxJpaEntity event = new SignalEventOutboxJpaEntity();
        event.setFarmId(farmId);
        event.setEventType(eventType.name());
        event.setEntityType(entityType);
        event.setEntityId(entityId);
        return event;
    }

    private FarmSignalRevision revision(long status, long position, long geometry) {
        return new FarmSignalRevision(1L, status, position, geometry, now);
    }

    private static final class MutableClock extends Clock {
        private Instant instant;

        private MutableClock(Instant instant) {
            this.instant = instant;
        }

        private void advance(Duration duration) {
            instant = instant.plus(duration);
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return instant;
        }
    }
}
