package com.smartlivestock.shared.security;

import com.smartlivestock.analytics.interfaces.ApiCallLogInterceptor;
import com.smartlivestock.licensing.domain.DeploymentLicenseState;
import com.smartlivestock.licensing.domain.LicenseRuntimeStatus;
import com.smartlivestock.licensing.domain.repository.DeploymentLicenseStateRepository;
import com.smartlivestock.platform.web.QuotaInterceptor;
import com.smartlivestock.shared.WebMvcConfig;
import com.smartlivestock.shared.common.MessageResolver;
import com.smartlivestock.shared.ratelimit.RateLimitInterceptor;
import com.smartlivestock.shared.scope.FarmScopeInterceptor;
import com.smartlivestock.shared.scope.ScopeInterceptor;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistration;

import java.lang.reflect.Field;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the on-premise license enforcement gate (NIX-184 T5,
 * design §11): mode gate, per-runtime-status matrix and the registered
 * include/exclude path declaration.
 */
@ExtendWith(MockitoExtension.class)
class LicenseEnforcementInterceptorTest {

    private static final Long TENANT_ID = 42L;

    @Mock
    private DeploymentLicenseStateRepository stateRepository;

    private MockHttpServletRequest request;
    private MockHttpServletResponse response;

    @BeforeEach
    void setUp() {
        request = new MockHttpServletRequest("GET", "/api/v1/farms/1/livestock");
        response = new MockHttpServletResponse();
        LocaleContextHolder.setLocale(Locale.ENGLISH); // stable message assertions
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        LocaleContextHolder.setLocale(null);
    }

    // ── HOSTED mode: always pass ─────────────────────────────────────

    @Test
    void hostedModePassesEvenWhenRuntimeStateWouldBlock() throws Exception {
        TenantContext.setCurrentTenant(TENANT_ID);
        stubState(LicenseRuntimeStatus.PENDING_ACTIVATION);
        LicenseEnforcementInterceptor interceptor = new LicenseEnforcementInterceptor(
                stateRepository, messageResolver(), "HOSTED");

        assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
        assertThat(response.getStatus()).isEqualTo(200);
    }

    // ── ONPREM mode matrix ───────────────────────────────────────────

    @Nested
    class OnPrem {

        private LicenseEnforcementInterceptor interceptor;

        @BeforeEach
        void setUp() {
            interceptor = new LicenseEnforcementInterceptor(stateRepository,
                    messageResolver(), "ONPREM");
        }

        @Test
        void missingTenantContextPassesThrough() throws Exception {
            // no TenantContext — platform admin cross-tenant operations are
            // guarded by the individual controllers
            assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
            assertThat(response.getContentAsString()).isEmpty();
        }

        @Test
        void pendingActivationBlocksBusinessApiWithLicenseRequiredJson() throws Exception {
            TenantContext.setCurrentTenant(TENANT_ID);
            stubState(LicenseRuntimeStatus.PENDING_ACTIVATION);

            assertThat(interceptor.preHandle(request, response, new Object())).isFalse();
            assertThat(response.getStatus()).isEqualTo(403);
            assertThat(response.getContentAsString())
                    .contains("\"code\":\"LICENSE_REQUIRED\"")
                    .contains("not activated")
                    .contains("\"requestId\":\"");
            assertThat(response.getContentType()).contains("application/json");
        }

        @Test
        void suspendedBlocksBusinessApiIncludingOpenPaths() throws Exception {
            TenantContext.setCurrentTenant(TENANT_ID);
            stubState(LicenseRuntimeStatus.SUSPENDED);
            request.setRequestURI("/api/v1/open/device/heartbeat");

            assertThat(interceptor.preHandle(request, response, new Object())).isFalse();
            assertThat(response.getStatus()).isEqualTo(403);
            assertThat(response.getContentAsString())
                    .contains("\"code\":\"LICENSE_REQUIRED\"")
                    .contains("suspended");
        }

        @Test
        void validRuntimePasses() throws Exception {
            TenantContext.setCurrentTenant(TENANT_ID);
            stubState(LicenseRuntimeStatus.VALID);

            assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
        }

        @Test
        void expiredRuntimePasses() throws Exception {
            TenantContext.setCurrentTenant(TENANT_ID);
            stubState(LicenseRuntimeStatus.EXPIRED);

            assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
        }

        @Test
        void missingStateRowPasses() throws Exception {
            TenantContext.setCurrentTenant(TENANT_ID);
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.empty());

            assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
        }

        @Test
        void nullRuntimeStatusPasses() throws Exception {
            TenantContext.setCurrentTenant(TENANT_ID);
            DeploymentLicenseState state = new DeploymentLicenseState();
            when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(state));

            assertThat(interceptor.preHandle(request, response, new Object())).isTrue();
        }
    }

    // ── WebMvcConfig registration declaration ────────────────────────

    @Nested
    class Registration {

        @Test
        void licenseGateIsRegisteredFirstWithDesignMatrixPaths() throws Exception {
            WebMvcConfig config = new WebMvcConfig(
                    mock(FarmScopeInterceptor.class), mock(QuotaInterceptor.class),
                    mock(RateLimitInterceptor.class), mock(ApiCallLogInterceptor.class),
                    mock(ScopeInterceptor.class),
                    new LicenseEnforcementInterceptor(stateRepository, messageResolver(), "ONPREM"));
            InterceptorRegistry registry = new InterceptorRegistry();
            config.addInterceptors(registry);

            List<InterceptorRegistration> registrations = registrationsOf(registry);
            assertThat(registrations).isNotEmpty();

            InterceptorRegistration licenseGate = registrations.get(0); // before quota
            assertThat(interceptorOf(licenseGate))
                    .isInstanceOf(LicenseEnforcementInterceptor.class);
            assertThat(patterns(licenseGate, "includePatterns", "pathPatterns"))
                    .containsExactly("/api/v1/**");
            assertThat(patterns(licenseGate, "excludePatterns", "excludePathPatterns"))
                    .containsExactlyInAnyOrder(
                            "/api/v1/auth/**",
                            "/api/v1/me/**",
                            "/api/v1/admin/deployment-license/**",
                            "/api/v1/admin/tenants/**",
                            // public deployment descriptor for the login screen
                            "/api/v1/deployment-info");
        }
    }

    // ── helpers ──────────────────────────────────────────────────────

    private void stubState(LicenseRuntimeStatus status) {
        DeploymentLicenseState state = DeploymentLicenseState.initial(TENANT_ID,
                Instant.parse("2026-09-03T10:00:00Z"));
        state.transitionTo(status, null, Instant.parse("2026-09-03T10:00:00Z"),
                null, null);
        // lenient: the HOSTED-mode test builds the state but never reads it
        lenient().when(stateRepository.findByTenantId(TENANT_ID)).thenReturn(Optional.of(state));
    }

    private static MessageResolver messageResolver() {
        ReloadableResourceBundleMessageSource source = new ReloadableResourceBundleMessageSource();
        source.setBasename("classpath:messages");
        source.setDefaultEncoding("UTF-8");
        return new MessageResolver(source);
    }

    private static List<InterceptorRegistration> registrationsOf(InterceptorRegistry registry)
            throws Exception {
        Field field = InterceptorRegistry.class.getDeclaredField("registrations");
        field.setAccessible(true);
        @SuppressWarnings("unchecked")
        List<InterceptorRegistration> registrations =
                (List<InterceptorRegistration>) field.get(registry);
        return registrations;
    }

    private static Object interceptorOf(InterceptorRegistration registration) throws Exception {
        Field field = InterceptorRegistration.class.getDeclaredField("interceptor");
        field.setAccessible(true);
        return field.get(registration);
    }

    /**
     * Collects the pattern lists from whichever backing field this Spring
     * version uses ({@code includePatterns}/{@code excludePatterns} in
     * Spring 6.1, parsed PathPattern lists in newer lines).
     */
    private static List<String> patterns(InterceptorRegistration registration,
                                         String... candidateFields) throws Exception {
        for (String fieldName : candidateFields) {
            Field field;
            try {
                field = InterceptorRegistration.class.getDeclaredField(fieldName);
            } catch (NoSuchFieldException e) {
                continue;
            }
            field.setAccessible(true);
            Object value = field.get(registration);
            if (value instanceof List<?> list) {
                List<String> result = new ArrayList<>();
                for (Object item : list) {
                    result.add(item instanceof org.springframework.web.util.pattern.PathPattern p
                            ? p.getPatternString() : String.valueOf(item));
                }
                return result;
            }
        }
        return List.of();
    }
}
