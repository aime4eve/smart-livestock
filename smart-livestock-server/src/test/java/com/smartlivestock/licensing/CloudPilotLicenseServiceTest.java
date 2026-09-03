package com.smartlivestock.licensing;

import com.smartlivestock.commerce.domain.model.Subscription;
import com.smartlivestock.commerce.domain.model.SubscriptionStatus;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.identity.domain.model.AuditLog;
import com.smartlivestock.identity.domain.repository.AuditLogRepository;
import com.smartlivestock.licensing.application.CloudPilotLicenseService;
import com.smartlivestock.licensing.application.PilotLicenseModeGuard;
import com.smartlivestock.licensing.application.port.LicenseSubscriptionPort;
import com.smartlivestock.licensing.infrastructure.config.PilotLicenseProperties;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CloudPilotLicenseServiceTest {

    private static final Long TARGET_TENANT_ID = 7L;
    private static final Long OPERATOR_USER_ID = 99L;

    @Mock
    private LicenseSubscriptionPort licenseSubscriptionPort;

    @Mock
    private AuditLogRepository auditLogRepository;

    private PilotLicenseProperties pilotLicenseProperties;
    private CloudPilotLicenseService service;

    @BeforeEach
    void setUp() {
        pilotLicenseProperties = new PilotLicenseProperties();
        pilotLicenseProperties.setEnabled(true);
        PilotLicenseModeGuard guard = new PilotLicenseModeGuard(pilotLicenseProperties, "HOSTED");
        service = new CloudPilotLicenseService(licenseSubscriptionPort, auditLogRepository, guard);
        authenticateAsPlatformAdmin();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateAsPlatformAdmin() {
        Authentication auth = new UsernamePasswordAuthenticationToken(
            OPERATOR_USER_ID, "N/A",
            List.of(new SimpleGrantedAuthority("ROLE_PLATFORM_ADMIN")));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    private LicenseSubscriptionPort.LicenseSubscriptionSnapshot snapshot(
            SubscriptionStatus status, Instant trialEndsAt, boolean trialActive) {
        return new LicenseSubscriptionPort.LicenseSubscriptionSnapshot(
            status.name(), trialEndsAt, trialActive);
    }

    // ── Grant paths ──────────────────────────────────────────────────

    @Nested
    class Grant {

        @Test
        void noSubscription_createsTrial365Days_andAuditsGrant() {
            when(licenseSubscriptionPort.findSubscription(TARGET_TENANT_ID))
                .thenReturn(Optional.empty());
            Instant before = Instant.now();

            CloudPilotLicenseService.PilotLicenseResult result =
                service.grantPilotLicense(TARGET_TENANT_ID);

            Instant after = Instant.now();
            ArgumentCaptor<Instant> trialEndsCaptor = ArgumentCaptor.forClass(Instant.class);
            verify(licenseSubscriptionPort).applyTrialLicense(eq(TARGET_TENANT_ID), trialEndsCaptor.capture());
            assertThat(trialEndsCaptor.getValue()).isCloseTo(
                before.plus(Duration.ofDays(365)), within(5, ChronoUnit.SECONDS));
            assertThat(trialEndsCaptor.getValue()).isCloseTo(
                after.plus(Duration.ofDays(365)), within(5, ChronoUnit.SECONDS));

            assertThat(result.tenantId()).isEqualTo(TARGET_TENANT_ID);
            assertThat(result.status()).isEqualTo("TRIAL");
            assertThat(result.trialEndsAt()).isEqualTo(trialEndsCaptor.getValue());

            ArgumentCaptor<AuditLog> auditCaptor = ArgumentCaptor.forClass(AuditLog.class);
            verify(auditLogRepository).save(auditCaptor.capture());
            AuditLog auditLog = auditCaptor.getValue();
            assertThat(auditLog.getEventType()).isEqualTo(CloudPilotLicenseService.EVENT_PILOT_LICENSE_GRANT);
            assertThat(auditLog.getTenantId()).isEqualTo(TARGET_TENANT_ID);
            assertThat(auditLog.getUserId()).isEqualTo(OPERATOR_USER_ID);
            assertThat(auditLog.getOperatorRole()).isEqualTo("PLATFORM_ADMIN");
            assertThat(auditLog.getDetails())
                .containsEntry("tenantId", TARGET_TENANT_ID)
                .containsEntry("previousStatus", "NONE")
                .containsKey("trialEndsAt");
        }

        @Test
        void activeTrialEndingEarlier_extendsToPilotEnd() {
            Instant currentEnd = Instant.now().plus(Duration.ofDays(14));
            when(licenseSubscriptionPort.findSubscription(TARGET_TENANT_ID))
                .thenReturn(Optional.of(snapshot(SubscriptionStatus.TRIAL, currentEnd, true)));

            CloudPilotLicenseService.PilotLicenseResult result =
                service.grantPilotLicense(TARGET_TENANT_ID);

            ArgumentCaptor<Instant> trialEndsCaptor = ArgumentCaptor.forClass(Instant.class);
            verify(licenseSubscriptionPort).applyTrialLicense(eq(TARGET_TENANT_ID), trialEndsCaptor.capture());
            assertThat(trialEndsCaptor.getValue()).isCloseTo(
                Instant.now().plus(Duration.ofDays(365)), within(5, ChronoUnit.SECONDS));
            assertThat(result.status()).isEqualTo("TRIAL");

            verify(auditLogRepository).save(any(AuditLog.class));
        }

        @Test
        void activeTrialEndingLater_keepsLongerCurrentEnd() {
            Instant currentEnd = Instant.now().plus(Duration.ofDays(400));
            when(licenseSubscriptionPort.findSubscription(TARGET_TENANT_ID))
                .thenReturn(Optional.of(snapshot(SubscriptionStatus.TRIAL, currentEnd, true)));

            CloudPilotLicenseService.PilotLicenseResult result =
                service.grantPilotLicense(TARGET_TENANT_ID);

            verify(licenseSubscriptionPort).applyTrialLicense(TARGET_TENANT_ID, currentEnd);
            assertThat(result.trialEndsAt()).isEqualTo(currentEnd);
        }
    }

    // ── Rejection paths ──────────────────────────────────────────────

    @Nested
    class Reject {

        @ParameterizedTest
        @EnumSource(value = SubscriptionStatus.class, mode = EnumSource.Mode.EXCLUDE, names = "TRIAL")
        void nonTrialStates_rejected_withAudit(SubscriptionStatus status) {
            when(licenseSubscriptionPort.findSubscription(TARGET_TENANT_ID))
                .thenReturn(Optional.of(snapshot(status, null, false)));

            assertThatThrownBy(() -> service.grantPilotLicense(TARGET_TENANT_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException apiEx = (ApiException) ex;
                    assertThat(apiEx.getCode()).isEqualTo(ErrorCode.STATE_CONFLICT);
                    assertThat(apiEx.getMessage()).isEqualTo("license.pilot.stateConflict");
                    assertThat(apiEx.getMessageArgs()).containsExactly(status.name());
                });

            verify(licenseSubscriptionPort, never()).applyTrialLicense(anyLong(), any(Instant.class));
            ArgumentCaptor<AuditLog> auditCaptor = ArgumentCaptor.forClass(AuditLog.class);
            verify(auditLogRepository).save(auditCaptor.capture());
            AuditLog auditLog = auditCaptor.getValue();
            assertThat(auditLog.getEventType()).isEqualTo(CloudPilotLicenseService.EVENT_PILOT_LICENSE_REJECTED);
            assertThat(auditLog.getDetails())
                .containsEntry("tenantId", TARGET_TENANT_ID)
                .containsEntry("currentStatus", status.name());
        }

        @Test
        void expiredTrial_rejected() {
            Instant pastEnd = Instant.now().minus(Duration.ofDays(1));
            when(licenseSubscriptionPort.findSubscription(TARGET_TENANT_ID))
                .thenReturn(Optional.of(snapshot(SubscriptionStatus.TRIAL, pastEnd, false)));

            assertThatThrownBy(() -> service.grantPilotLicense(TARGET_TENANT_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getCode())
                    .isEqualTo(ErrorCode.STATE_CONFLICT));

            verify(licenseSubscriptionPort, never()).applyTrialLicense(anyLong(), any(Instant.class));
            verify(auditLogRepository).save(any(AuditLog.class));
        }
    }

    // ── Mode / operator guards ───────────────────────────────────────

    @Nested
    class Guards {

        @Test
        void onPremMode_forbidden() {
            PilotLicenseModeGuard onPremGuard =
                new PilotLicenseModeGuard(pilotLicenseProperties, "ONPREM");
            CloudPilotLicenseService onPremService =
                new CloudPilotLicenseService(licenseSubscriptionPort, auditLogRepository, onPremGuard);

            assertThatThrownBy(() -> onPremService.grantPilotLicense(TARGET_TENANT_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    assertThat(((ApiException) ex).getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN);
                    assertThat(((ApiException) ex).getMessage()).isEqualTo("license.pilot.modeForbidden");
                });

            verifyNoInteractions(licenseSubscriptionPort);
            verifyNoInteractions(auditLogRepository);
        }

        @Test
        void disabledPilot_forbidden() {
            pilotLicenseProperties.setEnabled(false);

            assertThatThrownBy(() -> service.grantPilotLicense(TARGET_TENANT_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    assertThat(((ApiException) ex).getCode()).isEqualTo(ErrorCode.AUTH_FORBIDDEN);
                    assertThat(((ApiException) ex).getMessage()).isEqualTo("license.pilot.modeForbidden");
                });

            verifyNoInteractions(licenseSubscriptionPort);
        }

        @Test
        void modeIsCaseInsensitive() {
            PilotLicenseModeGuard lowerGuard =
                new PilotLicenseModeGuard(pilotLicenseProperties, "hosted");
            CloudPilotLicenseService lowerService =
                new CloudPilotLicenseService(licenseSubscriptionPort, auditLogRepository, lowerGuard);
            when(licenseSubscriptionPort.findSubscription(TARGET_TENANT_ID))
                .thenReturn(Optional.empty());

            CloudPilotLicenseService.PilotLicenseResult result =
                lowerService.grantPilotLicense(TARGET_TENANT_ID);

            assertThat(result.status()).isEqualTo("TRIAL");
        }

        @Test
        void missingAuthentication_rejected() {
            SecurityContextHolder.clearContext();

            assertThatThrownBy(() -> service.grantPilotLicense(TARGET_TENANT_ID))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    assertThat(((ApiException) ex).getCode()).isEqualTo(ErrorCode.AUTH_INVALID_TOKEN);
                    assertThat(((ApiException) ex).getMessage()).isEqualTo("license.pilot.operatorMissing");
                });

            verifyNoInteractions(licenseSubscriptionPort);
        }
    }
}
