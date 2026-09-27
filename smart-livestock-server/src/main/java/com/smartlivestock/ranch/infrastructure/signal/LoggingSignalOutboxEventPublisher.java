package com.smartlivestock.ranch.infrastructure.signal;

import com.smartlivestock.ranch.application.signal.SignalOutboxEventPublisher;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/** Default transport until SSE registers a concrete in-process publisher. */
@Slf4j
@Component
public class LoggingSignalOutboxEventPublisher implements SignalOutboxEventPublisher {

    @Override
    public void publish(SignalEventOutboxJpaEntity event) {
        log.debug("Dispatched signal event {} for farm [{}] {} [{}]",
                event.getEventType(), event.getFarmId(),
                event.getEntityType(), event.getEntityId());
    }
}
