package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.service.EstrusFeedbackService;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.common.GlobalExceptionHandler;
import com.smartlivestock.shared.common.MessageResolver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Locale;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Thin controller tests for the estrus verdict endpoint (NIX-286 Task 2):
 * happy-path FeedbackResult passthrough, the service ApiException mapping
 * (404 / 400 / 403 via the global handler) and the unauthenticated 401.
 * Service semantics (idempotency, episode restore, label writes) are covered
 * by {@code EstrusFeedbackServiceTest}; the {@code @PreAuthorize} role guard
 * is enforced by method security in the full application context and is not
 * exercised by this standalone MockMvc setup.
 */
@ExtendWith(MockitoExtension.class)
class EstrusFeedbackControllerTest {

    private static final String BASE = "/api/v1/farms/1/alerts/11/estrus-feedback";

    @Mock
    private EstrusFeedbackService estrusFeedbackService;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        LocaleContextHolder.setLocale(Locale.ENGLISH); // stable message assertions
        GlobalExceptionHandler advice = new GlobalExceptionHandler(
                new MessageResolver(testMessageSource()));
        mvc = MockMvcBuilders.standaloneSetup(new EstrusFeedbackController(estrusFeedbackService))
                .setControllerAdvice(advice)
                .build();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        LocaleContextHolder.setLocale(null);
    }

    /** AlertController reads the principal as a Long userId — same here. */
    private void loginAs(Long userId, String... roles) {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken(userId, "n/a", roles));
    }

    // ── Happy path ──────────────────────────────────────────────

    @Test
    void submitReturnsFeedbackResultFields() throws Exception {
        loginAs(9L, "ROLE_OWNER");
        when(estrusFeedbackService.submitFeedback(1L, 11L, true, 9L))
                .thenReturn(new EstrusFeedbackService.FeedbackResult(11L, "CONFIRMED", 77L, 99L, false));

        mvc.perform(post(BASE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"confirmed\": true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.alertId").value(11))
                .andExpect(jsonPath("$.data.verdict").value("CONFIRMED"))
                .andExpect(jsonPath("$.data.physiologyEventId").value(77))
                .andExpect(jsonPath("$.data.labelId").value(99))
                .andExpect(jsonPath("$.data.idempotent").value(false));
    }

    // ── Service ApiException passthrough (global handler) ───────

    @Test
    void unknownAlertPassesThroughAs404() throws Exception {
        loginAs(9L, "ROLE_OWNER");
        when(estrusFeedbackService.submitFeedback(1L, 11L, false, 9L))
                .thenThrow(new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "error.estrusFeedback.alertNotFound"));

        mvc.perform(post(BASE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"confirmed\": false}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void nonEstrusAlertPassesThroughAs400() throws Exception {
        loginAs(9L, "ROLE_OWNER");
        when(estrusFeedbackService.submitFeedback(1L, 11L, true, 9L))
                .thenThrow(new ApiException(ErrorCode.VALIDATION_ERROR, "error.estrusFeedback.notEstrusAlert"));

        mvc.perform(post(BASE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"confirmed\": true}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }

    @Test
    void crossFarmAlertPassesThroughAs403() throws Exception {
        loginAs(9L, "ROLE_OWNER");
        when(estrusFeedbackService.submitFeedback(1L, 11L, true, 9L))
                .thenThrow(new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.estrusFeedback.farmMismatch"));

        mvc.perform(post(BASE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"confirmed\": true}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("AUTH_FORBIDDEN"));
    }

    // ── Request validation ──────────────────────────────────────

    /** A missing {@code confirmed} must not silently mean "rejected". */
    @Test
    void missingConfirmedFieldIsRejectedAs400() throws Exception {
        loginAs(9L, "ROLE_OWNER");

        mvc.perform(post(BASE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"note\": \"no verdict flag\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        verifyNoInteractions(estrusFeedbackService);
    }

    // ── Authentication ──────────────────────────────────────────

    @Test
    void unauthenticatedRequestIsRejectedAs401() throws Exception {
        // No SecurityContext authentication — mirrors an empty principal.
        mvc.perform(post(BASE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"confirmed\": true}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("AUTH_INVALID_TOKEN"));

        verifyNoInteractions(estrusFeedbackService);
    }

    // ── Helpers ─────────────────────────────────────────────────

    private static ReloadableResourceBundleMessageSource testMessageSource() {
        ReloadableResourceBundleMessageSource source = new ReloadableResourceBundleMessageSource();
        source.setBasename("classpath:messages");
        source.setDefaultEncoding("UTF-8");
        source.setUseCodeAsDefaultMessage(true);
        return source;
    }
}
