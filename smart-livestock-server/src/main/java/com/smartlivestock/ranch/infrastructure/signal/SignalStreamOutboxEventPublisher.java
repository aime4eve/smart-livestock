package com.smartlivestock.ranch.infrastructure.signal;

import com.smartlivestock.ranch.application.signal.SignalOutboxEventPublisher;
import com.smartlivestock.ranch.application.signal.SignalStreamNotificationService;
import com.smartlivestock.ranch.infrastructure.persistence.entity.SignalEventOutboxJpaEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class SignalStreamOutboxEventPublisher implements SignalOutboxEventPublisher {

    private final SignalStreamNotificationService notificationService;

    @Override
    public void publish(SignalEventOutboxJpaEntity event) {
        notificationService.accept(event);
    }
}
