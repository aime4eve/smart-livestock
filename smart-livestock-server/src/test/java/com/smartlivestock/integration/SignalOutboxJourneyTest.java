package com.smartlivestock.integration;

import com.smartlivestock.ranch.application.AlertApplicationService;
import com.smartlivestock.ranch.application.dto.AlertDto;
import com.smartlivestock.ranch.application.signal.SignalEventType;
import com.smartlivestock.ranch.application.signal.SignalOutboxDispatcher;
import com.smartlivestock.ranch.application.signal.SignalOutboxEventPublisher;
import com.smartlivestock.ranch.domain.model.AlertType;
import com.smartlivestock.ranch.domain.model.Severity;
import com.smartlivestock.ranch.infrastructure.persistence.SignalEventOutboxJpaRepository;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "signal.outbox.poll-ms=PT1H"
)
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class SignalOutboxJourneyTest extends AbstractJourneyTest {

    @Autowired
    private AlertApplicationService alertApplicationService;
    @Autowired
    private SignalEventOutboxJpaRepository outboxRepository;
    @Autowired
    private SignalOutboxDispatcher dispatcher;
    @Autowired
    private TransactionTemplate transactionTemplate;
    @MockBean
    private SignalOutboxEventPublisher eventPublisher;

    @Test
    @DisplayName("alert change persists an outbox hint in the business transaction")
    void successfulBusinessChangeWritesOutbox() {
        AlertDto alert = createAlert();

        List<SignalEventOutboxJpaEntity> events = findByEntity(alert.id());
        assertThat(events).hasSize(1);
        assertThat(events.get(0).getEventType())
                .isEqualTo(SignalEventType.ALERT_CHANGED.name());
        assertThat(events.get(0).getStatus()).isEqualTo("PENDING");
        assertThat(events.get(0).getPayload())
                .contains("\"farmId\":1")
                .contains("\"entityType\":\"ALERT\"")
                .contains("\"entityId\":" + alert.id());
    }

    @Test
    @DisplayName("rolling back the business transaction also removes its outbox hint")
    void businessRollbackRemovesOutboxHint() {
        long before = outboxRepository.count();

        transactionTemplate.executeWithoutResult(status -> {
            AlertDto alert = createAlert();
            assertThat(findByEntity(alert.id())).hasSize(1);
            status.setRollbackOnly();
        });

        assertThat(outboxRepository.count()).isEqualTo(before);
    }

    @Test
    @DisplayName("repeated entity changes merge into one pending final notification")
    void pendingEntityEventsCoalesce() {
        AlertDto alert = createAlert();
        alertApplicationService.markRead(alert.id(), currentUserId());
        alertApplicationService.markRead(alert.id(), currentUserId());

        assertThat(findByEntity(alert.id())).hasSize(1);

        int dispatched = dispatcher.dispatchDueBatch();
        assertThat(dispatched).isGreaterThanOrEqualTo(1);
        assertThat(findByEntity(alert.id())).hasSize(1);
        assertThat(findByEntity(alert.id()).get(0).getStatus()).isEqualTo("DISPATCHED");
    }

    @Test
    @DisplayName("locked pending rows are skipped by another dispatcher")
    void concurrentDispatchersDoNotConsumeTheSameRow() throws Exception {
        createAlert();

        CountDownLatch publisherEntered = new CountDownLatch(1);
        CountDownLatch releasePublisher = new CountDownLatch(1);
        doAnswer(invocation -> {
            publisherEntered.countDown();
            releasePublisher.await(5, TimeUnit.SECONDS);
            return null;
        }).when(eventPublisher).publish(any());

        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<Integer> first = executor.submit(() ->
                    transactionTemplate.execute(status -> dispatcher.dispatchDueBatch()));
            assertThat(publisherEntered.await(5, TimeUnit.SECONDS)).isTrue();

            Integer second = transactionTemplate.execute(status -> dispatcher.dispatchDueBatch());
            assertThat(second).isZero();

            releasePublisher.countDown();
            assertThat(first.get(5, TimeUnit.SECONDS)).isGreaterThanOrEqualTo(1);
        } finally {
            releasePublisher.countDown();
            executor.shutdownNow();
        }
    }

    private AlertDto createAlert() {
        return alertApplicationService.createAlert(
                1L,
                AlertType.FENCE_BREACH,
                Severity.WARNING,
                "Signal outbox journey test " + System.nanoTime()
        );
    }

    private List<SignalEventOutboxJpaEntity> findByEntity(Long alertId) {
        return outboxRepository.findAll().stream()
                .filter(event -> "ALERT".equals(event.getEntityType()))
                .filter(event -> alertId.equals(event.getEntityId()))
                .toList();
    }

    private Long currentUserId() {
        return 1L;
    }
}
