package com.smartlivestock.licensing.interfaces;

import com.smartlivestock.licensing.application.DeploymentLicenseApplicationService;
import com.smartlivestock.licensing.application.LicenseModeGuard;
import com.smartlivestock.licensing.application.PilotLicenseModeGuard;
import com.smartlivestock.licensing.infrastructure.config.PilotLicenseProperties;
import com.smartlivestock.licensing.interfaces.admin.DeploymentLicenseAdminController;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.GlobalExceptionHandler;
import com.smartlivestock.shared.common.MessageResolver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.Locale;
import java.util.Set;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Thin controller tests for the on-premise deployment license admin API
 * (NIX-184 T5): platform-admin guard, HOSTED/ONPREM mode gate and the
 * multipart import branches. Service behavior itself is covered by
 * {@code DeploymentLicenseApplicationServiceTest}.
 */
@ExtendWith(MockitoExtension.class)
class DeploymentLicenseAdminControllerTest {

    private static final Long TENANT_ID = 42L;
    private static final String BASE = "/api/v1/admin/deployment-license";

    @Mock
    private DeploymentLicenseApplicationService applicationService;

    private MockMvc onPremMvc;
    private MockMvc hostedMvc;

    @BeforeEach
    void setUp() {
        LocaleContextHolder.setLocale(Locale.ENGLISH); // stable message assertions

        GlobalExceptionHandler advice = new GlobalExceptionHandler(
                new MessageResolver(testMessageSource()));

        onPremMvc = build(new DeploymentLicenseAdminController(applicationService,
                new LicenseModeGuard("ONPREM"),
                new PilotLicenseModeGuard(pilotProperties(true), "ONPREM")), advice);
        hostedMvc = build(new DeploymentLicenseAdminController(applicationService,
                new LicenseModeGuard("HOSTED"),
                new PilotLicenseModeGuard(pilotProperties(true), "HOSTED")), advice);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        LocaleContextHolder.setLocale(null);
    }

    // ── platform_admin guard ─────────────────────────────────────────

    @Nested
    class PlatformAdminGuard {

        @Test
        void nonPlatformAdminIsRejectedOnEveryEndpoint() throws Exception {
            loginAs("ROLE_TENANT_ADMIN");

            onPremMvc.perform(get(BASE + "/enrollment").param("tenantId", "42"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));
            onPremMvc.perform(get(BASE + "/current").param("tenantId", "42"))
                    .andExpect(status().isForbidden());
            onPremMvc.perform(get(BASE + "/mode"))
                    .andExpect(status().isForbidden());

            verifyNoInteractions(applicationService);
        }

        @Test
        void unauthenticatedIsRejected() throws Exception {
            onPremMvc.perform(get(BASE + "/mode"))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.code").value("AUTH_INVALID_TOKEN"));
        }
    }

    // ── HOSTED mode gate ─────────────────────────────────────────────

    @Nested
    class HostedMode {

        @Test
        void enrollmentIsOnPremOnly() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            hostedMvc.perform(get(BASE + "/enrollment").param("tenantId", "42"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"))
                    .andExpect(jsonPath("$.message")
                            .value("This endpoint is only available in ONPREM deployment mode"));

            verify(applicationService, never()).enroll(TENANT_ID);
        }

        @Test
        void currentIsOnPremOnly() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            hostedMvc.perform(get(BASE + "/current").param("tenantId", "42"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));

            verify(applicationService, never()).currentStatus(TENANT_ID);
        }

        @Test
        void importIsOnPremOnly() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            hostedMvc.perform(multipart(BASE)
                            .file(envelopeFile("{\"payload\":{}}"))
                            .param("tenantId", "42")
                            .param("confirm", "true"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));

            verify(applicationService, never()).importLicense(eq(TENANT_ID), eq("{\"payload\":{}}"),
                    eq(true));
        }

        @Test
        void modeEndpointIsUsableInEveryMode() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            hostedMvc.perform(get(BASE + "/mode"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.code").value("OK"))
                    .andExpect(jsonPath("$.data.mode").value("HOSTED"))
                    .andExpect(jsonPath("$.data.pilotLicenseEnabled").value(true));

            verifyNoInteractions(applicationService);
        }
    }

    // ── ONPREM happy paths / multipart branches ──────────────────────

    @Nested
    class OnPremMode {

        @Test
        void enrollmentReturnsAssembledDto() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(applicationService.enroll(TENANT_ID)).thenReturn(new EnrollmentInfoFixture().info());

            onPremMvc.perform(get(BASE + "/enrollment").param("tenantId", "42"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.tenantId").value(42))
                    .andExpect(jsonPath("$.data.installationId").value("inst-1"))
                    .andExpect(jsonPath("$.data.fingerprintHash").value("fp-sha256"))
                    .andExpect(jsonPath("$.data.publicKeyId").value("key-2026-09"))
                    .andExpect(jsonPath("$.data.supportedPublicKeyIds.length()").value(1));
        }

        @Test
        void currentReturnsStatusDto() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(applicationService.currentStatus(TENANT_ID)).thenReturn(new StatusFixture().status());

            onPremMvc.perform(get(BASE + "/current").param("tenantId", "42"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.runtimeStatus").value("VALID"))
                    .andExpect(jsonPath("$.data.licenseType").value("ACTIVE"))
                    .andExpect(jsonPath("$.data.effectiveTier").value("PREMIUM"))
                    // standalone MockMvc serializes Instant as epoch nanoseconds;
                    // ISO formatting is applied by the Boot-configured mapper
                    .andExpect(jsonPath("$.data.maxObservedAt").exists());
        }

        @Test
        void modeReportsOnPremAndDisabledPilot() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            onPremMvc.perform(get(BASE + "/mode"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.mode").value("ONPREM"))
                    .andExpect(jsonPath("$.data.pilotLicenseEnabled").value(false));
        }

        @Test
        void multipartImportWithFileAndConfirmSucceeds() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(applicationService.importLicense(TENANT_ID, "{\"payload\":{}}", true))
                    .thenReturn(new ImportResultFixture().result());

            onPremMvc.perform(multipart(BASE)
                            .file(envelopeFile("{\"payload\":{}}"))
                            .param("tenantId", "42")
                            .param("confirm", "true"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.licenseId").value("lic-1"))
                    .andExpect(jsonPath("$.data.runtimeStatus").value("VALID"))
                    .andExpect(jsonPath("$.data.effectiveTier").value("PREMIUM"));

            verify(applicationService).importLicense(TENANT_ID, "{\"payload\":{}}", true);
        }

        @Test
        void multipartImportWithoutConfirmPropagatesFalseAndIsRefused() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(applicationService.importLicense(TENANT_ID, "{\"payload\":{}}", false))
                    .thenThrow(new ApiException(ErrorCode.VALIDATION_ERROR,
                            "license.import.confirmRequired"));

            onPremMvc.perform(multipart(BASE)
                            .file(envelopeFile("{\"payload\":{}}"))
                            .param("tenantId", "42")) // confirm omitted → false
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

            verify(applicationService).importLicense(TENANT_ID, "{\"payload\":{}}", false);
        }

        @Test
        void multipartImportWithoutFileIsValidationErrorBeforeService() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            onPremMvc.perform(multipart(BASE)
                            .param("tenantId", "42")
                            .param("confirm", "true"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                    .andExpect(jsonPath("$.message")
                            .value("Please choose a license file to import"));

            verifyNoInteractions(applicationService);
        }

        @Test
        void oversizedFileIsRejectedBeforeService() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            byte[] huge = new byte[DeploymentLicenseAdminController.MAX_ENVELOPE_BYTES + 1];

            onPremMvc.perform(multipart(BASE)
                            .file(new MockMultipartFile("file", "license.json",
                                    MediaType.APPLICATION_JSON_VALUE, huge))
                            .param("tenantId", "42")
                            .param("confirm", "true"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

            verifyNoInteractions(applicationService);
        }

        @Test
        void malformedEnvelopeSurfacesLicenseInvalidFromService() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(applicationService.importLicense(TENANT_ID, "not-a-json", true))
                    .thenThrow(new ApiException(ErrorCode.LICENSE_INVALID, "license.invalid"));

            onPremMvc.perform(multipart(BASE)
                            .file(envelopeFile("not-a-json"))
                            .param("tenantId", "42")
                            .param("confirm", "true"))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("LICENSE_INVALID"));
        }
    }

    // ── helpers ──────────────────────────────────────────────────────

    private void loginAs(String... roles) {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken("operator", "n/a", roles));
    }

    private static MockMultipartFile envelopeFile(String content) {
        return new MockMultipartFile("file", "license.json",
                MediaType.APPLICATION_JSON_VALUE, content.getBytes());
    }

    private static MockMvc build(DeploymentLicenseAdminController controller,
                                 GlobalExceptionHandler advice) {
        return MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(advice)
                .build();
    }

    private static ReloadableResourceBundleMessageSource testMessageSource() {
        ReloadableResourceBundleMessageSource source = new ReloadableResourceBundleMessageSource();
        source.setBasename("classpath:messages");
        source.setDefaultEncoding("UTF-8");
        source.setUseCodeAsDefaultMessage(true);
        return source;
    }

    private static PilotLicenseProperties pilotProperties(boolean enabled) {
        PilotLicenseProperties properties = new PilotLicenseProperties();
        properties.setEnabled(enabled);
        return properties;
    }

    /** Fixtures kept as tiny inner classes to avoid long argument lists inline. */
    private static final class EnrollmentInfoFixture {
        DeploymentLicenseApplicationService.EnrollmentInfo info() {
            return new DeploymentLicenseApplicationService.EnrollmentInfo(TENANT_ID, "inst-1",
                    "fp-sha256", "key-2026-09", Set.of("key-2026-09"),
                    Instant.parse("2026-09-03T10:00:00Z"));
        }
    }

    private static final class ImportResultFixture {
        DeploymentLicenseApplicationService.ImportResult result() {
            return new DeploymentLicenseApplicationService.ImportResult(TENANT_ID, "lic-1",
                    "ACTIVE", "PREMIUM", "PREMIUM", Instant.parse("2027-09-03T10:00:00Z"),
                    "VALID");
        }
    }

    private static final class StatusFixture {
        DeploymentLicenseApplicationService.DeploymentLicenseStatus status() {
            return new DeploymentLicenseApplicationService.DeploymentLicenseStatus(TENANT_ID,
                    "inst-1", "fp-sha256", "VALID", "lic-1", "ACTIVE", "PREMIUM", "PREMIUM",
                    Instant.parse("2026-09-03T08:00:00Z"), Instant.parse("2027-09-03T10:00:00Z"),
                    Instant.parse("2026-09-03T08:01:00Z"), Instant.parse("2026-09-03T09:00:00Z"),
                    "VALID", null, Instant.parse("2026-09-03T10:00:00Z"), null,
                    "ACTIVE", null);
        }
    }
}
