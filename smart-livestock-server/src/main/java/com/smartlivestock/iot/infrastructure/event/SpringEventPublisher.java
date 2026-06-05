package com.smartlivestock.iot.infrastructure.event;

import com.smartlivestock.iot.domain.event.DeviceActivatedEvent;
import com.smartlivestock.iot.domain.event.GpsLogUpdatedEvent;
import com.smartlivestock.iot.domain.event.LicenseExpiredEvent;
import com.smartlivestock.iot.domain.event.TelemetryReceivedEvent;
import com.smartlivestock.ranch.domain.event.AlertStatusChangedEvent;
import com.smartlivestock.ranch.domain.event.FenceBreachDetectedEvent;
import com.smartlivestock.shared.domain.event.*;
import com.smartlivestock.shared.messaging.RocketMQEventPublisher;
import com.smartlivestock.shared.messaging.Topics;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Bridge that listens for Spring ApplicationEvents published by application services
 * and forwards them to RocketMQ via {@link RocketMQEventPublisher}.
 * <p>
 * This is the central Spring -> RocketMQ event bridge. All cross-context domain events
 * flow through here to their respective RocketMQ topics.
 */
@Slf4j
@Component
public class SpringEventPublisher {

    private final RocketMQEventPublisher rocketMQEventPublisher;

    public SpringEventPublisher(RocketMQEventPublisher rocketMQEventPublisher) {
        this.rocketMQEventPublisher = rocketMQEventPublisher;
    }

    // ── IoT Events ─────────────────────────────────────────────

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
    public void onTelemetryReceived(TelemetryReceivedEvent event) {
        log.info("Bridging TelemetryReceivedEvent for device [{}], type [{}]",
                event.getDeviceId(), event.getDeviceType());
        rocketMQEventPublisher.publish(Topics.TELEMETRY_RECEIVED, event);
    }

    // ── Ranch Events ───────────────────────────────────────────

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

    // ── Commerce Events (shared.domain.event) ──────────────────

    @EventListener
    public void onSubscriptionCreated(SubscriptionCreatedEvent event) {
        rocketMQEventPublisher.publish(Topics.SUBSCRIPTION_CREATED, event);
    }

    @EventListener
    public void onSubscriptionTierChanged(SubscriptionTierChangedEvent event) {
        rocketMQEventPublisher.publish(Topics.SUBSCRIPTION_TIER_CHANGED, event);
    }

    @EventListener
    public void onSubscriptionSuspended(SubscriptionSuspendedEvent event) {
        rocketMQEventPublisher.publish(Topics.SUBSCRIPTION_SUSPENDED, event);
    }

    @EventListener
    public void onSubscriptionReactivated(SubscriptionReactivatedEvent event) {
        rocketMQEventPublisher.publish(Topics.SUBSCRIPTION_REACTIVATED, event);
    }

    @EventListener
    public void onSubscriptionExpired(SubscriptionExpiredEvent event) {
        rocketMQEventPublisher.publish(Topics.SUBSCRIPTION_EXPIRED, event);
    }

    @EventListener
    public void onContractSigned(ContractSignedEvent event) {
        rocketMQEventPublisher.publish(Topics.CONTRACT_SIGNED, event);
    }

    @EventListener
    public void onServiceDegraded(ServiceDegradedEvent event) {
        rocketMQEventPublisher.publish(Topics.SERVICE_DEGRADED, event);
    }

    @EventListener
    public void onServiceRevoked(ServiceRevokedEvent event) {
        rocketMQEventPublisher.publish(Topics.SERVICE_REVOKED, event);
    }

    @EventListener
    public void onServiceQuotaAdjusted(ServiceQuotaAdjustedEvent event) {
        rocketMQEventPublisher.publish(Topics.SERVICE_QUOTA_ADJUSTED, event);
    }
}
