package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.infrastructure.persistence.SignalEventOutboxJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.jpa.repository.Query;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SignalOutboxDispatcherTest {

    @Mock
    private SignalEventOutboxJpaRepository repository;
    @Mock
    private SignalOutboxEventPublisher publisher;

    private SignalOutboxDispatcher dispatcher;

    @BeforeEach
    void setUp() {
        dispatcher = new SignalOutboxDispatcher(repository, publisher);
    }

    @Test
    void successfulDispatchMarksEvent() {
        SignalEventOutboxJpaEntity event = event(1L, 0, "PENDING");
        when(repository.findDispatchableIds(100)).thenReturn(List.of(1L));
        when(repository.findAllById(List.of(1L))).thenReturn(List.of(event));

        assertThat(dispatcher.dispatchDueBatch()).isEqualTo(1);
        assertThat(event.getStatus()).isEqualTo("DISPATCHED");
        assertThat(event.getDispatchedAt()).isNotNull();
        assertThat(event.getLastError()).isNull();
    }

    @Test
    void failedDispatchIncrementsRetryAndSchedulesBackoff() {
        SignalEventOutboxJpaEntity event = event(2L, 0, "PENDING");
        Instant before = Instant.now();
        when(repository.findDispatchableIds(100)).thenReturn(List.of(2L));
        when(repository.findAllById(List.of(2L))).thenReturn(List.of(event));
        org.mockito.Mockito.doThrow(new IllegalStateException("transport down"))
                .when(publisher).publish(event);

        dispatcher.dispatchDueBatch();

        assertThat(event.getStatus()).isEqualTo("PENDING");
        assertThat(event.getRetryCount()).isEqualTo(1);
        assertThat(event.getAvailableAt()).isAfter(before);
        assertThat(event.getLastError()).contains("transport down");
    }

    @Test
    void maxRetriesMarksEventFailed() {
        SignalEventOutboxJpaEntity event = event(3L, 0, "PENDING");
        when(repository.findDispatchableIds(100)).thenReturn(List.of(3L));
        when(repository.findAllById(List.of(3L))).thenReturn(List.of(event));
        org.mockito.Mockito.doThrow(new IllegalStateException("still down"))
                .when(publisher).publish(event);

        for (int attempt = 0; attempt < 5; attempt++) {
            dispatcher.dispatchDueBatch();
        }

        assertThat(event.getStatus()).isEqualTo("FAILED");
        assertThat(event.getRetryCount()).isEqualTo(5);
        verify(publisher, times(5)).publish(event);
    }

    @Test
    void claimContractUsesSkipLocked() throws NoSuchMethodException {
        Query query = SignalEventOutboxJpaRepository.class
                .getMethod("findDispatchableIds", int.class)
                .getAnnotation(Query.class);

        assertThat(query).isNotNull();
        assertThat(query.value()).contains("FOR UPDATE SKIP LOCKED");
    }

    private SignalEventOutboxJpaEntity event(Long id, int retryCount, String status) {
        SignalEventOutboxJpaEntity event = new SignalEventOutboxJpaEntity();
        event.setId(id);
        event.setFarmId(1L);
        event.setEventType(SignalEventType.ALERT_CHANGED.name());
        event.setEntityType("ALERT");
        event.setEntityId(20L);
        event.setPayload("{\"farmId\":1,\"entityType\":\"ALERT\",\"entityId\":20}");
        event.setStatus(status);
        event.setRetryCount(retryCount);
        event.setAvailableAt(Instant.now().minusSeconds(1));
        return event;
    }
}
