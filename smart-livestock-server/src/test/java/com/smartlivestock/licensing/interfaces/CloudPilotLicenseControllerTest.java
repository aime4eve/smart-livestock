package com.smartlivestock.licensing.interfaces;

import com.smartlivestock.licensing.application.CloudPilotLicenseService;
import com.smartlivestock.licensing.application.PilotLicenseModeGuard;
import com.smartlivestock.licensing.infrastructure.config.PilotLicenseProperties;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Controller tests for the hosted pilot-license endpoint mode gate
 * (NIX-184 T5): ONPREM deployments must never grant pilot licenses even
 * when the feature flag is on (design §7).
 */
@ExtendWith(MockitoExtension.class)
class CloudPilotLicenseControllerTest {

    private static final Long TENANT_ID = 42L;

    @Mock
    private CloudPilotLicenseService cloudPilotLicenseService;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void onPremDeploymentRejectsPilotGrantEvenWhenFlagEnabled() {
        loginAs("ROLE_PLATFORM_ADMIN");
        CloudPilotLicenseController controller =
                new CloudPilotLicenseController(cloudPilotLicenseService, guard(true, "ONPREM"));

        assertThatThrownBy(() -> controller.grantPilotLicense(TENANT_ID, null))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode())
                        .isEqualTo(ErrorCode.AUTH_FORBIDDEN))
                .hasMessage("license.pilot.modeForbidden");

        verifyNoInteractions(cloudPilotLicenseService);
    }

    @Test
    void hostedDeploymentWithFlagGrantsPilotLicense() {
        loginAs("ROLE_PLATFORM_ADMIN");
        CloudPilotLicenseController controller =
                new CloudPilotLicenseController(cloudPilotLicenseService, guard(true, "HOSTED"));
        when(cloudPilotLicenseService.grantPilotLicense(TENANT_ID, null))
                .thenReturn(new CloudPilotLicenseService.PilotLicenseResult(
                        TENANT_ID, "TRIAL", Instant.parse("2027-09-03T08:00:00Z")));

        ResponseEntity<?> response = controller.grantPilotLicense(TENANT_ID, null);

        assertThat(response.getStatusCode().value()).isEqualTo(200);
    }

    @Test
    void requestedDeadlineForwardedToService() {
        loginAs("ROLE_PLATFORM_ADMIN");
        CloudPilotLicenseController controller =
                new CloudPilotLicenseController(cloudPilotLicenseService, guard(true, "HOSTED"));
        java.util.Map<String, Object> body =
                java.util.Map.of("trialEndsAt", "2027-09-30T21:00:00Z");
        Instant requested = Instant.parse("2027-09-30T21:00:00Z");
        when(cloudPilotLicenseService.grantPilotLicense(TENANT_ID, requested))
                .thenReturn(new CloudPilotLicenseService.PilotLicenseResult(
                        TENANT_ID, "TRIAL", requested));

        ResponseEntity<?> response = controller.grantPilotLicense(TENANT_ID, body);

        assertThat(response.getStatusCode().value()).isEqualTo(200);
    }

    @Test
    void unparseableDeadlineRejectedBeforeService() {
        loginAs("ROLE_PLATFORM_ADMIN");
        CloudPilotLicenseController controller =
                new CloudPilotLicenseController(cloudPilotLicenseService, guard(true, "HOSTED"));

        assertThatThrownBy(() -> controller.grantPilotLicense(TENANT_ID,
                java.util.Map.of("trialEndsAt", "not-a-date")))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode())
                        .isEqualTo(ErrorCode.VALIDATION_ERROR));

        verifyNoInteractions(cloudPilotLicenseService);
    }

    @Test
    void nonPlatformAdminIsRejected() {
        loginAs("ROLE_TENANT_ADMIN");
        CloudPilotLicenseController controller =
                new CloudPilotLicenseController(cloudPilotLicenseService, guard(true, "HOSTED"));

        assertThatThrownBy(() -> controller.grantPilotLicense(TENANT_ID, null))
                .isInstanceOf(ApiException.class)
                .satisfies(e -> assertThat(((ApiException) e).getCode())
                        .isEqualTo(ErrorCode.AUTH_FORBIDDEN));

        verifyNoInteractions(cloudPilotLicenseService);
    }

    private void loginAs(String... roles) {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken("operator", "n/a", roles));
    }

    private static PilotLicenseModeGuard guard(boolean enabled, String mode) {
        PilotLicenseProperties properties = new PilotLicenseProperties();
        properties.setEnabled(enabled);
        return new PilotLicenseModeGuard(properties, mode);
    }
}
