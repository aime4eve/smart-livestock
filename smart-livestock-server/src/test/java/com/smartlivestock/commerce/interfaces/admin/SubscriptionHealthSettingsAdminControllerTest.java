package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsProvider.HealthThresholds;
import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsService;
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
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import java.util.Locale;
import java.util.Map;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Thin controller tests for the platform-configurable NIX-324 banner tier
 * API (V20261103100000): platform-admin guard, tier validation and the
 * read-after-write round trip. Service behavior is covered by
 * {@code SubscriptionSemanticsCrossCheckTest} for evaluator effects.
 */
@ExtendWith(MockitoExtension.class)
class SubscriptionHealthSettingsAdminControllerTest {

    private static final String BASE = "/api/v1/admin/subscription-health-settings";

    @Mock
    private SubscriptionHealthSettingsService settingsService;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        LocaleContextHolder.setLocale(Locale.ENGLISH); // stable message assertions

        GlobalExceptionHandler advice = new GlobalExceptionHandler(
                new MessageResolver(testMessageSource()));

        mvc = MockMvcBuilders.standaloneSetup(
                        new SubscriptionHealthSettingsAdminController(settingsService))
                .setControllerAdvice(advice)
                .build();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        LocaleContextHolder.setLocale(null);
    }

    private void loginAs(String... roles) {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken(1L, "n/a", roles));
    }

    // ── platform_admin guard ─────────────────────────────────────────

    @Nested
    class PlatformAdminGuard {

        @Test
        void nonPlatformAdminIsRejectedOnEveryEndpoint() throws Exception {
            loginAs("ROLE_B2B_ADMIN");

            mvc.perform(get(BASE))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));
            mvc.perform(put(BASE).contentType(MediaType.APPLICATION_JSON)
                            .content("{\"warnDays\":30,\"cautionDays\":10,\"dangerDays\":5}"))
                    .andExpect(status().isForbidden());

            verifyNoInteractions(settingsService);
        }

        @Test
        void platformAdminGetsCurrentTiers() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(settingsService.get()).thenReturn(HealthThresholds.defaults());

            mvc.perform(get(BASE))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.warnDays").value(14))
                    .andExpect(jsonPath("$.data.cautionDays").value(7))
                    .andExpect(jsonPath("$.data.dangerDays").value(3));
        }
    }

    // ── update branches ──────────────────────────────────────────────

    @Nested
    class Update {

        @Test
        void validTiersRoundTrip() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");
            when(settingsService.update(eq(30), eq(10), eq(5), eq(1L), eq("ROLE_PLATFORM_ADMIN")))
                    .thenReturn(new HealthThresholds(30, 10, 5));

            mvc.perform(put(BASE).contentType(MediaType.APPLICATION_JSON)
                            .content("{\"warnDays\":30,\"cautionDays\":10,\"dangerDays\":5}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.warnDays").value(30))
                    .andExpect(jsonPath("$.data.cautionDays").value(10))
                    .andExpect(jsonPath("$.data.dangerDays").value(5));

            verify(settingsService).update(eq(30), eq(10), eq(5), eq(1L), eq("ROLE_PLATFORM_ADMIN"));
        }

        @Test
        void nonOrderedTiersReturnValidationError() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            mvc.perform(put(BASE).contentType(MediaType.APPLICATION_JSON)
                            .content("{\"warnDays\":10,\"cautionDays\":10,\"dangerDays\":3}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

            verify(settingsService, never()).update(
                    org.mockito.ArgumentMatchers.anyInt(), org.mockito.ArgumentMatchers.anyInt(),
                    org.mockito.ArgumentMatchers.anyInt(),
                    org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
        }

        @Test
        void missingFieldReturnsValidationError() throws Exception {
            loginAs("ROLE_PLATFORM_ADMIN");

            mvc.perform(put(BASE).contentType(MediaType.APPLICATION_JSON)
                            .content("{\"warnDays\":14,\"cautionDays\":7}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        }
    }

    private static org.springframework.context.support.ReloadableResourceBundleMessageSource testMessageSource() {
        org.springframework.context.support.ReloadableResourceBundleMessageSource source =
                new org.springframework.context.support.ReloadableResourceBundleMessageSource();
        source.setBasename("classpath:messages");
        source.setDefaultEncoding("UTF-8");
        source.setUseCodeAsDefaultMessage(true);
        return source;
    }
}
