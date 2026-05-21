package com.smartlivestock.platform.messaging;

import com.smartlivestock.commerce.domain.model.event.ContractCreatedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractExpiredEvent;
import com.smartlivestock.commerce.domain.model.event.ContractReactivatedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractSuspendedEvent;
import com.smartlivestock.commerce.domain.model.event.ContractTerminatedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePartnerConfirmedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePeriodCreatedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenuePlatformConfirmedEvent;
import com.smartlivestock.commerce.domain.model.event.RevenueSettledEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceActivatedEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceHeartbeatLostEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceHeartbeatRecoveredEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceProvisionedEvent;
import com.smartlivestock.commerce.domain.model.event.SubscriptionCancelledEvent;
import com.smartlivestock.commerce.domain.model.event.SubscriptionRenewalFailedEvent;
import com.smartlivestock.identity.domain.event.TenantPhaseChangedEvent;
import com.smartlivestock.iot.domain.event.DeviceActivatedEvent;
import com.smartlivestock.iot.domain.event.GpsLogUpdatedEvent;
import com.smartlivestock.iot.domain.event.LicenseExpiredEvent;
import com.smartlivestock.ranch.domain.event.AlertStatusChangedEvent;
import com.smartlivestock.ranch.domain.event.FenceBreachDetectedEvent;
import com.smartlivestock.shared.domain.event.ContractSignedEvent;
import com.smartlivestock.shared.domain.event.ServiceDegradedEvent;
import com.smartlivestock.shared.domain.event.ServiceQuotaAdjustedEvent;
import com.smartlivestock.shared.domain.event.ServiceRevokedEvent;
import com.smartlivestock.shared.domain.event.SubscriptionCreatedEvent;
import com.smartlivestock.shared.domain.event.SubscriptionExpiredEvent;
import com.smartlivestock.shared.domain.event.SubscriptionReactivatedEvent;
import com.smartlivestock.shared.domain.event.SubscriptionSuspendedEvent;
import com.smartlivestock.shared.domain.event.SubscriptionTierChangedEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Platform-level notification event listener.
 * Listens to all domain events across all bounded contexts (Commerce, Identity, IoT, Ranch)
 * and creates notification records in the notifications table.
 * <p>
 * Uses Spring's synchronous @EventListener — events are processed in the same transaction
 * as the publisher. For MVP, no async or MQ-based processing is needed.
 */
@Slf4j
@Component
public class NotificationEventListener {

    private final NotificationService notificationService;

    public NotificationEventListener(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    // ======================== Shared cross-context events (9) ========================

    @EventListener
    public void onSubscriptionCreated(SubscriptionCreatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_created",
                "订阅创建成功",
                String.format("租户已创建 %s 级别订阅", event.getTier()));
    }

    @EventListener
    public void onSubscriptionTierChanged(SubscriptionTierChangedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_tier_changed",
                "订阅等级变更",
                String.format("订阅等级已从 %s 变更为 %s", event.getOldTier(), event.getNewTier()));
    }

    @EventListener
    public void onSubscriptionSuspended(SubscriptionSuspendedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_suspended",
                "订阅已暂停",
                "您的订阅已被暂停，部分功能可能受限");
    }

    @EventListener
    public void onSubscriptionReactivated(SubscriptionReactivatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_reactivated",
                "订阅已恢复",
                "您的订阅已恢复，所有功能已重新开放");
    }

    @EventListener
    public void onSubscriptionExpired(SubscriptionExpiredEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_expired",
                "订阅已过期",
                "您的订阅已过期，请及时续费以免影响使用");
    }

    @EventListener
    public void onContractSigned(ContractSignedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "contract_signed",
                "合同已签署",
                String.format("合同 %s 已成功签署", event.getContractNumber()));
    }

    @EventListener
    public void onServiceDegraded(ServiceDegradedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_degraded",
                "服务降级通知",
                String.format("服务 %s 已降级，请联系管理员", event.getServiceName()));
    }

    @EventListener
    public void onServiceQuotaAdjusted(ServiceQuotaAdjustedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_quota_adjusted",
                "服务配额调整",
                String.format("服务 %s 配额已调整为 %d", event.getServiceName(), event.getNewQuota()));
    }

    @EventListener
    public void onServiceRevoked(ServiceRevokedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_revoked",
                "服务已撤销",
                String.format("服务 %s 已被撤销", event.getServiceName()));
    }

    // ======================== Internal Commerce events (15) ========================

    @EventListener
    public void onSubscriptionCancelled(SubscriptionCancelledEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_cancelled",
                "订阅已取消",
                "您的订阅已被取消");
    }

    @EventListener
    public void onSubscriptionRenewalFailed(SubscriptionRenewalFailedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "subscription_renewal_failed",
                "续费失败",
                "订阅自动续费失败，请检查支付信息或手动续费");
    }

    @EventListener
    public void onContractCreated(ContractCreatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "contract_created",
                "合同已创建",
                String.format("合同 %s 已创建，等待签署", event.getContractNumber()));
    }

    @EventListener
    public void onContractSuspended(ContractSuspendedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "contract_suspended",
                "合同已暂停",
                String.format("合同 %s 已暂停", event.getContractNumber()));
    }

    @EventListener
    public void onContractReactivated(ContractReactivatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "contract_reactivated",
                "合同已恢复",
                String.format("合同 %s 已恢复执行", event.getContractNumber()));
    }

    @EventListener
    public void onContractTerminated(ContractTerminatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "contract_terminated",
                "合同已终止",
                String.format("合同 %s 已终止", event.getContractNumber()));
    }

    @EventListener
    public void onContractExpired(ContractExpiredEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "contract_expired",
                "合同已到期",
                String.format("合同 %s 已到期", event.getContractNumber()));
    }

    @EventListener
    public void onRevenuePeriodCreated(RevenuePeriodCreatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "revenue_period_created",
                "分润账期已创建",
                String.format("合同 %d 的新分润账期已创建", event.getContractId()));
    }

    @EventListener
    public void onRevenuePlatformConfirmed(RevenuePlatformConfirmedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "revenue_platform_confirmed",
                "平台已确认分润",
                String.format("合同 %d 的分润账期已由平台确认", event.getContractId()));
    }

    @EventListener
    public void onRevenuePartnerConfirmed(RevenuePartnerConfirmedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "revenue_partner_confirmed",
                "合作方已确认分润",
                String.format("合同 %d 的分润账期已由合作方确认", event.getContractId()));
    }

    @EventListener
    public void onRevenueSettled(RevenueSettledEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "revenue_settled",
                "分润已结算",
                String.format("合同 %d 的分润已结算完成", event.getContractId()));
    }

    @EventListener
    public void onServiceProvisioned(ServiceProvisionedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_provisioned",
                "服务已开通",
                String.format("服务 %s 已开通配置", event.getServiceName()));
    }

    @EventListener
    public void onServiceActivated(ServiceActivatedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_activated",
                "服务已激活",
                String.format("服务 %s 已激活可用", event.getServiceName()));
    }

    @EventListener
    public void onServiceHeartbeatLost(ServiceHeartbeatLostEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_heartbeat_lost",
                "服务心跳丢失",
                String.format("服务 %s 心跳丢失，请检查设备状态", event.getServiceName()));
    }

    @EventListener
    public void onServiceHeartbeatRecovered(ServiceHeartbeatRecoveredEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "service_heartbeat_recovered",
                "服务心跳恢复",
                String.format("服务 %s 心跳已恢复正常", event.getServiceName()));
    }

    // ======================== Non-Commerce events (6) ========================

    @EventListener
    public void onTenantPhaseChanged(TenantPhaseChangedEvent event) {
        notificationService.createNotification(
                event.getTenantId(), null, "tenant_phase_changed",
                "租户阶段变更",
                String.format("租户阶段已变更为 %s", event.getNewPhase()));
    }

    @EventListener
    public void onDeviceActivated(DeviceActivatedEvent event) {
        // Device events lack tenantId — defer notification to context layer
        // which can resolve device → installation → tenant
        log.debug("DeviceActivated event received for device [{}] — tenant-scoped notification deferred to context layer",
                event.getDeviceId());
    }

    @EventListener
    public void onGpsLogUpdated(GpsLogUpdatedEvent event) {
        // GPS log updates are high-frequency — skip notification generation to avoid noise
        log.trace("GpsLogUpdated event received for device [{}] — skipped for notification", event.getDeviceId());
    }

    @EventListener
    public void onLicenseExpired(LicenseExpiredEvent event) {
        // License events lack tenantId — defer to context layer
        log.debug("LicenseExpired event received for license [{}] — tenant-scoped notification deferred to context layer",
                event.getLicenseId());
    }

    @EventListener
    public void onAlertStatusChanged(AlertStatusChangedEvent event) {
        // Alert events lack tenantId — defer to context layer
        log.debug("AlertStatusChanged event received for alert [{}] to [{}] — notification deferred to context layer",
                event.getAlertId(), event.getNewStatus());
    }

    @EventListener
    public void onFenceBreachDetected(FenceBreachDetectedEvent event) {
        // Fence breach events lack tenantId — defer to context layer
        log.debug("FenceBreachDetected event received for livestock [{}] at fence [{}] — notification deferred to context layer",
                event.getLivestockId(), event.getFenceId());
    }
}
