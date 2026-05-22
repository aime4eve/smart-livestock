package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.commerce.domain.model.event.ServiceActivatedEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceHeartbeatLostEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceHeartbeatRecoveredEvent;
import com.smartlivestock.commerce.domain.model.event.ServiceProvisionedEvent;
import com.smartlivestock.shared.common.DomainException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.event.ServiceDegradedEvent;
import com.smartlivestock.shared.domain.event.ServiceQuotaAdjustedEvent;
import com.smartlivestock.shared.domain.event.ServiceRevokedEvent;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.*;

class SubscriptionServiceTest {

    private static final Long TENANT_ID = 1L;
    private static final String SERVICE_NAME = "gps-tracking";
    private static final String RAW_SERVICE_KEY = "sk-abcdef1234567890ghijkl";

    // ── Factory helpers ──────────────────────────────────────────────

    private SubscriptionService createProvisionedService() {
        return SubscriptionService.provision(
            TENANT_ID, SERVICE_NAME, RAW_SERVICE_KEY,
            SubscriptionTier.STANDARD, 200
        );
    }

    private SubscriptionService createActiveService() {
        SubscriptionService svc = createProvisionedService();
        svc.clearDomainEvents();
        Instant expiresAt = Instant.now().plusSeconds(365 * 86400);
        svc.activate(expiresAt);
        svc.clearDomainEvents();
        return svc;
    }

    // ── provision ────────────────────────────────────────────────────

    @Nested
    class Provision {

        @Test
        void setsProvisionedStatusAndFields() {
            SubscriptionService svc = createProvisionedService();

            assertThat(svc.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(svc.getServiceName()).isEqualTo(SERVICE_NAME);
            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.PROVISIONED);
            assertThat(svc.getEffectiveTier()).isEqualTo("standard");
            assertThat(svc.getDeviceQuota()).isEqualTo(200);
            assertThat(svc.getStartedAt()).isNotNull();
            assertThat(svc.getExpiresAt()).isNull();
            assertThat(svc.getLastHeartbeatAt()).isNull();
            assertThat(svc.getGraceEndsAt()).isNull();
            assertThat(svc.getHeartbeatIntervalHrs()).isEqualTo(24);
            assertThat(svc.getGracePeriodDays()).isEqualTo(7);
        }

        @Test
        void hashesServiceKeyAndExtractsPrefix() {
            SubscriptionService svc = createProvisionedService();

            assertThat(svc.getServiceKeyPrefix()).isNotNull();
            assertThat(svc.getServiceKeyPrefix()).hasSize(8);
            assertThat(svc.getServiceKeyPrefix()).isEqualTo(svc.getServiceKeyHash().substring(0, 8));
            assertThat(svc.getServiceKeyHash()).isNotNull();
            assertThat(svc.getServiceKeyHash()).hasSize(64); // SHA-256 hex
        }

        @Test
        void registersServiceProvisionedEvent() {
            SubscriptionService svc = createProvisionedService();

            assertThat(svc.getDomainEvents()).hasSize(1);
            ServiceProvisionedEvent event = (ServiceProvisionedEvent) svc.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getServiceName()).isEqualTo(SERVICE_NAME);
        }
    }

    // ── activate ─────────────────────────────────────────────────────

    @Nested
    class Activate {

        @Test
        void transitionsToActive() {
            SubscriptionService svc = createProvisionedService();
            svc.clearDomainEvents();

            Instant expiresAt = Instant.now().plusSeconds(365 * 86400);
            svc.activate(expiresAt);

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.ACTIVE);
            assertThat(svc.getExpiresAt()).isEqualTo(expiresAt);
            assertThat(svc.getLastHeartbeatAt()).isNotNull();
        }

        @Test
        void registersServiceActivatedEvent() {
            SubscriptionService svc = createProvisionedService();
            svc.clearDomainEvents();

            Instant expiresAt = Instant.now().plusSeconds(365 * 86400);
            svc.activate(expiresAt);

            assertThat(svc.getDomainEvents()).hasSize(1);
            ServiceActivatedEvent event = (ServiceActivatedEvent) svc.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getServiceName()).isEqualTo(SERVICE_NAME);
        }

        @Test
        void rejectsFromNonProvisioned() {
            SubscriptionService svc = createActiveService();

            assertThatThrownBy(() -> svc.activate(Instant.now()))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── recordHeartbeat ──────────────────────────────────────────────

    @Nested
    class RecordHeartbeat {

        @Test
        void updatesLastHeartbeatAt() {
            SubscriptionService svc = createActiveService();

            svc.recordHeartbeat();

            assertThat(svc.getLastHeartbeatAt()).isNotNull();
        }

        @Test
        void fromGracePeriod_transitionsBackToActive() {
            SubscriptionService svc = createActiveService();
            // Force into GRACE_PERIOD by simulating overdue heartbeat
            svc.setLastHeartbeatAt(Instant.now().minusSeconds(48 * 3600));
            svc.checkHeartbeat();
            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.GRACE_PERIOD);
            svc.clearDomainEvents();

            svc.recordHeartbeat();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.ACTIVE);
            assertThat(svc.getDomainEvents()).hasSize(1);
            assertThat(svc.getDomainEvents().get(0)).isInstanceOf(ServiceHeartbeatRecoveredEvent.class);
        }

        @Test
        void rejectsFromProvisioned() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(svc::recordHeartbeat)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromExpired() {
            SubscriptionService svc = createActiveService();
            svc.revoke();

            assertThatThrownBy(svc::recordHeartbeat)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── checkHeartbeat ───────────────────────────────────────────────

    @Nested
    class CheckHeartbeat {

        @Test
        void whenHeartbeatOverdue_transitionsToGracePeriod() {
            SubscriptionService svc = createActiveService();
            // Simulate overdue heartbeat by setting lastHeartbeatAt far in the past
            svc.setLastHeartbeatAt(Instant.now().minusSeconds(48 * 3600)); // 48 hours ago
            svc.clearDomainEvents();

            svc.checkHeartbeat();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.GRACE_PERIOD);
            assertThat(svc.getGraceEndsAt()).isNotNull();
            assertThat(svc.getDomainEvents()).hasSize(1);
            assertThat(svc.getDomainEvents().get(0)).isInstanceOf(ServiceHeartbeatLostEvent.class);
        }

        @Test
        void whenHeartbeatRecent_staysActive() {
            SubscriptionService svc = createActiveService();
            // lastHeartbeatAt was just set by activate()
            svc.clearDomainEvents();

            svc.checkHeartbeat();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.ACTIVE);
            assertThat(svc.getDomainEvents()).isEmpty();
        }

        @Test
        void rejectsFromProvisioned() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(svc::checkHeartbeat)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromExpired() {
            SubscriptionService svc = createActiveService();
            svc.revoke();
            svc.clearDomainEvents();

            assertThatThrownBy(svc::checkHeartbeat)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── degrade ──────────────────────────────────────────────────────

    @Nested
    class Degrade {

        @Test
        void transitionsFromGracePeriodToDegraded() {
            SubscriptionService svc = createActiveService();
            // Force into GRACE_PERIOD by simulating overdue heartbeat
            svc.setLastHeartbeatAt(Instant.now().minusSeconds(48 * 3600));
            svc.checkHeartbeat();
            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.GRACE_PERIOD);
            svc.clearDomainEvents();

            svc.degrade();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.DEGRADED);
            assertThat(svc.getDomainEvents()).hasSize(1);
            assertThat(svc.getDomainEvents().get(0)).isInstanceOf(ServiceDegradedEvent.class);
        }

        @Test
        void rejectsFromActive() {
            SubscriptionService svc = createActiveService();

            assertThatThrownBy(svc::degrade)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── revoke ───────────────────────────────────────────────────────

    @Nested
    class Revoke {

        @Test
        void transitionsFromActiveToExpired() {
            SubscriptionService svc = createActiveService();

            svc.revoke();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.EXPIRED);
            assertThat(svc.getDomainEvents()).hasSize(1);
            ServiceRevokedEvent event = (ServiceRevokedEvent) svc.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getServiceName()).isEqualTo(SERVICE_NAME);
        }

        @Test
        void transitionsFromProvisionedToExpired() {
            SubscriptionService svc = createProvisionedService();
            svc.clearDomainEvents();

            svc.revoke();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.EXPIRED);
            assertThat(svc.getDomainEvents()).hasSize(1);
            assertThat(svc.getDomainEvents().get(0)).isInstanceOf(ServiceRevokedEvent.class);
        }

        @Test
        void transitionsFromGracePeriodToExpired() {
            SubscriptionService svc = createActiveService();
            // Force into GRACE_PERIOD by simulating overdue heartbeat
            svc.setLastHeartbeatAt(Instant.now().minusSeconds(48 * 3600));
            svc.checkHeartbeat();
            svc.clearDomainEvents();

            svc.revoke();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.EXPIRED);
            assertThat(svc.getDomainEvents()).hasSize(1);
            assertThat(svc.getDomainEvents().get(0)).isInstanceOf(ServiceRevokedEvent.class);
        }

        @Test
        void rejectsFromExpired() {
            SubscriptionService svc = createActiveService();
            svc.revoke();
            svc.clearDomainEvents();

            assertThatThrownBy(svc::revoke)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── expire ───────────────────────────────────────────────────────

    @Nested
    class Expire {

        @Test
        void transitionsFromActiveToExpired() {
            SubscriptionService svc = createActiveService();

            svc.expire();

            assertThat(svc.getStatus()).isEqualTo(SubscriptionServiceStatus.EXPIRED);
            assertThat(svc.getDomainEvents()).hasSize(1);
            assertThat(svc.getDomainEvents().get(0)).isInstanceOf(ServiceRevokedEvent.class);
        }

        @Test
        void rejectsFromProvisioned() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(svc::expire)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromExpired() {
            SubscriptionService svc = createActiveService();
            svc.expire();
            svc.clearDomainEvents();

            assertThatThrownBy(svc::expire)
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── adjustQuota ──────────────────────────────────────────────────

    @Nested
    class AdjustQuota {

        @Test
        void updatesQuotaAndRegistersEvent() {
            SubscriptionService svc = createActiveService();

            svc.adjustQuota(500);

            assertThat(svc.getDeviceQuota()).isEqualTo(500);
            assertThat(svc.getDomainEvents()).hasSize(1);
            ServiceQuotaAdjustedEvent event = (ServiceQuotaAdjustedEvent) svc.getDomainEvents().get(0);
            assertThat(event.getTenantId()).isEqualTo(TENANT_ID);
            assertThat(event.getServiceName()).isEqualTo(SERVICE_NAME);
            assertThat(event.getNewQuota()).isEqualTo(500);
        }

        @Test
        void rejectsFromProvisioned() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(() -> svc.adjustQuota(500))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }

        @Test
        void rejectsFromExpired() {
            SubscriptionService svc = createActiveService();
            svc.revoke();
            svc.clearDomainEvents();

            assertThatThrownBy(() -> svc.adjustQuota(500))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.STATE_CONFLICT));
        }
    }

    // ── verifyKey ────────────────────────────────────────────────────

    @Nested
    class VerifyKey {

        @Test
        void acceptsCorrectKey() {
            SubscriptionService svc = createProvisionedService();

            assertThatCode(() -> svc.verifyKey(RAW_SERVICE_KEY)).doesNotThrowAnyException();
        }

        @Test
        void rejectsWrongKey() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(() -> svc.verifyKey("wrong-key"))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.SERVICE_KEY_MISMATCH));
        }

        @Test
        void rejectsNullKey() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(() -> svc.verifyKey(null))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.SERVICE_KEY_MISMATCH));
        }

        @Test
        void rejectsEmptyKey() {
            SubscriptionService svc = createProvisionedService();

            assertThatThrownBy(() -> svc.verifyKey(""))
                .isInstanceOf(DomainException.class)
                .satisfies(ex -> assertThat(((DomainException) ex).getCode()).isEqualTo(ErrorCode.SERVICE_KEY_MISMATCH));
        }
    }
}
