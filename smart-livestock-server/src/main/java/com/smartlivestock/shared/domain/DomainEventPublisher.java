package com.smartlivestock.shared.domain;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

/**
 * Utility helper that bridges domain events from an {@link AggregateRoot} to Spring's
 * {@link ApplicationEventPublisher}.
 * <p>
 * ApplicationServices should call {@link #publishDomainEvents(AggregateRoot)} after
 * saving an aggregate. This method publishes all registered domain events via Spring's
 * event bus and then clears them from the aggregate.
 * <p>
 * For MVP, uses Spring's synchronous ApplicationEvent mechanism — no RocketMQ.
 */
@Slf4j
@Component
public class DomainEventPublisher {

    private final ApplicationEventPublisher applicationEventPublisher;

    public DomainEventPublisher(ApplicationEventPublisher applicationEventPublisher) {
        this.applicationEventPublisher = applicationEventPublisher;
    }

    /**
     * Publish all domain events registered on the given aggregate root,
     * then clear them from the aggregate.
     *
     * @param aggregate the aggregate root whose domain events to publish
     */
    public void publishDomainEvents(AggregateRoot aggregate) {
        for (DomainEvent event : aggregate.getDomainEvents()) {
            log.debug("Publishing domain event: {}", event.getClass().getSimpleName());
            applicationEventPublisher.publishEvent(event);
        }
        aggregate.clearDomainEvents();
    }
}
