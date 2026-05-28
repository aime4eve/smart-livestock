package com.smartlivestock.iot.infrastructure.event;

import com.smartlivestock.iot.domain.event.DeviceActivatedEvent;
import com.smartlivestock.iot.domain.event.GpsLogUpdatedEvent;
import com.smartlivestock.iot.domain.event.LicenseExpiredEvent;
import com.smartlivestock.ranch.domain.event.AlertStatusChangedEvent;
import com.smartlivestock.ranch.domain.event.FenceBreachDetectedEvent;
import com.smartlivestock.shared.messaging.RocketMQEventPublisher;
import com.smartlivestock.shared.messaging.Topics;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Bridge that listens for Spring ApplicationEvents published by application services
 * and forwards them to RocketMQ via {@link RocketMQEventPublisher}.
 * <p>
 * This is the central Spring → RocketMQ event bridge. Application services publish
 * domain events using Spring's {@link org.springframework.context.ApplicationEventPublisher},
 * and this component picks them up and distributes them to the appropriate RocketMQ topics.
 * <p>
 * Each bounded context's events are forwarded to the topic defined in {@link Topics}.
 */
@Slf4j
@Component
public class SpringEventPublisher {

    private final RocketMQEventPublisher rocketMQEventPublisher;

    public SpringEventPublisher(RocketMQEventPublisher rocketMQEventPublisher) {
        this.rocketMQEventPublisher = rocketMQEventPublisher;
    }

    @EventListener
    public void onGpsLogUpdated(GpsLogUpdatedEvent event) {
        log.info("Bridging GpsLogUpdatedEvent for device [{}]", event.getDeviceId());
        rocketMQEventPublisher.publish(Topics.GPS_LOG_UPDATED, event);
    }

    @EventListener
    public void onDeviceActivated(DeviceActivatedEvent event) {
        log.info("Bridging DeviceActivatedEvent for device [{}]", event.getDeviceId());
        rocketMQEventPublisher.publish(Topics.DEVICE_ACTIVATED, event);
    }

    @EventListener
    public void onLicenseExpired(LicenseExpiredEvent event) {
        log.info("Bridging LicenseExpiredEvent for license [{}]", event.getLicenseId());
        rocketMQEventPublisher.publish(Topics.LICENSE_EXPIRED, event);
    }

    @EventListener
    public void onFenceBreachDetected(FenceBreachDetectedEvent event) {
        log.info("Bridging FenceBreachDetectedEvent for livestock [{}]", event.getLivestockId());
        rocketMQEventPublisher.publish(Topics.FENCE_BREACH_DETECTED, event);
    }

    @EventListener
    public void onAlertStatusChanged(AlertStatusChangedEvent event) {
        log.info("Bridging AlertStatusChangedEvent for alert [{}] to [{}]",
                event.getAlertId(), event.getNewStatus());
        rocketMQEventPublisher.publish(Topics.ALERT_STATUS_CHANGED, event);
    }
}
