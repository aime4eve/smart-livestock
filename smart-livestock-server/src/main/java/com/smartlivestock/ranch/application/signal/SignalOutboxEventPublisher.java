package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;

public interface SignalOutboxEventPublisher {
    void publish(SignalEventOutboxJpaEntity event);
}
