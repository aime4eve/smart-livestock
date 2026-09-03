package com.smartlivestock.commerce.interfaces;

import com.smartlivestock.commerce.application.dto.SubscriptionResponse;
import com.smartlivestock.commerce.application.query.SubscriptionQueryService;
import com.smartlivestock.commerce.application.service.SubscriptionApplicationService;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataSubscriptionRepository;
import com.smartlivestock.commerce.interfaces.admin.AdminSubscriptionController;
import com.smartlivestock.commerce.interfaces.app.SubscriptionController;
import com.smartlivestock.licensing.application.LicenseModeGuard;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Verifies the ONPREM self-service disablement on commerce subscription
 * mutation endpoints (NIX-184 T5, design §11): ONPREM throws
 * LICENSE_REQUIRED (license.selfServiceDisabled), HOSTED keeps the original
 * behavior. Read endpoints stay usable in ONPREM.
 */
@ExtendWith(MockitoExtension.class)
class SubscriptionSelfServiceGuardTest {

    private static final Long TENANT_ID = 42L;

    @Mock
    private SubscriptionApplicationService subscriptionApplicationService;
    @Mock
    private SubscriptionQueryService subscriptionQueryService;
    @Mock
    private SpringDataSubscriptionRepository springDataSubscriptionRepository;

    @BeforeEach
    void setUp() {
        TenantContext.setCurrentTenant(TENANT_ID);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    // ── app self-service endpoints ───────────────────────────────────

    @Nested
    class AppSelfService {

        @Test
        void onPremCheckoutIsRejectedWithLicenseRequired() {
            SubscriptionController controller = new SubscriptionController(
                    subscriptionApplicationService, subscriptionQueryService,
                    new LicenseModeGuard("ONPREM"));

            assertThatThrownBy(() -> controller.checkout(Map.of("tier", "PREMIUM")))
                    .isInstanceOf(ApiException.class)
                    .satisfies(e -> assertThat(((ApiException) e).getCode())
                            .isEqualTo(ErrorCode.LICENSE_REQUIRED))
                    .hasMessage("license.selfServiceDisabled");

            verifyNoInteractions(subscriptionApplicationService);
        }

        @Test
        void onPremTierChangeIsRejectedWithLicenseRequired() {
            SubscriptionController controller = new SubscriptionController(
                    subscriptionApplicationService, subscriptionQueryService,
                    new LicenseModeGuard("ONPREM"));

            assertThatThrownBy(() -> controller.upgradeTier(Map.of("tier", "STANDARD")))
                    .isInstanceOf(ApiException.class)
                    .satisfies(e -> assertThat(((ApiException) e).getCode())
                            .isEqualTo(ErrorCode.LICENSE_REQUIRED));

            verifyNoInteractions(subscriptionApplicationService);
        }

        @Test
        void onPremCancelIsRejectedWithLicenseRequired() {
            SubscriptionController controller = new SubscriptionController(
                    subscriptionApplicationService, subscriptionQueryService,
                    new LicenseModeGuard("ONPREM"));

            assertThatThrownBy(controller::cancel)
                    .isInstanceOf(ApiException.class)
                    .satisfies(e -> assertThat(((ApiException) e).getCode())
                            .isEqualTo(ErrorCode.LICENSE_REQUIRED));

            verifyNoInteractions(subscriptionApplicationService);
        }

        @Test
        void hostedCheckoutKeepsWorking() {
            SubscriptionController controller = new SubscriptionController(
                    subscriptionApplicationService, subscriptionQueryService,
                    new LicenseModeGuard("HOSTED"));
            when(subscriptionQueryService.findByTenantId(TENANT_ID))
                    .thenReturn(Optional.of(subscription("PREMIUM", "ACTIVE")));

            ResponseEntity<ApiResponse<SubscriptionResponse>> response =
                    controller.checkout(Map.of("tier", "PREMIUM"));

            assertThat(response.getStatusCode().value()).isEqualTo(200);
            assertThat(response.getBody()).isNotNull();
            assertThat(response.getBody().getData().getTier()).isEqualTo("PREMIUM");
            verify(subscriptionApplicationService).upgrade(eq(TENANT_ID),
                    eq(SubscriptionTier.PREMIUM), any());
        }
    }

    // ── admin manual status change ───────────────────────────────────

    @Nested
    class AdminManualStatusChange {

        @Test
        void onPremManualStatusChangeIsRejectedWithLicenseRequired() {
            loginAsPlatformAdmin();
            AdminSubscriptionController controller = new AdminSubscriptionController(
                    subscriptionApplicationService, subscriptionQueryService,
                    springDataSubscriptionRepository, new LicenseModeGuard("ONPREM"));

            assertThatThrownBy(() -> controller.updateStatus(5L,
                            Map.of("targetStatus", "SUSPENDED")))
                    .isInstanceOf(ApiException.class)
                    .satisfies(e -> assertThat(((ApiException) e).getCode())
                            .isEqualTo(ErrorCode.LICENSE_REQUIRED))
                    .hasMessage("license.selfServiceDisabled");

            verifyNoInteractions(springDataSubscriptionRepository);
            verifyNoInteractions(subscriptionApplicationService);
        }

        @Test
        void hostedManualStatusChangeReachesBusinessLogic() {
            loginAsPlatformAdmin();
            AdminSubscriptionController controller = new AdminSubscriptionController(
                    subscriptionApplicationService, subscriptionQueryService,
                    springDataSubscriptionRepository, new LicenseModeGuard("HOSTED"));
            // empty repo result → controller falls through the guard and fails
            // on the (mocked) business lookup with RESOURCE_NOT_FOUND
            when(springDataSubscriptionRepository.findById(5L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> controller.updateStatus(5L,
                            Map.of("targetStatus", "SUSPENDED")))
                    .isInstanceOf(ApiException.class)
                    .satisfies(e -> assertThat(((ApiException) e).getCode())
                            .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND));

            verifyNoInteractions(subscriptionApplicationService);
        }
    }

    // ── read endpoints stay usable in ONPREM ─────────────────────────

    @Test
    void onPremReadEndpointsStayUsable() {
        SubscriptionController controller = new SubscriptionController(
                subscriptionApplicationService, subscriptionQueryService,
                new LicenseModeGuard("ONPREM"));
        when(subscriptionQueryService.findByTenantId(TENANT_ID))
                .thenReturn(Optional.of(subscription("BASIC", "FREE")));

        ResponseEntity<ApiResponse<SubscriptionResponse>> response = controller.getSubscription();

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getData().getStatus()).isEqualTo("FREE");
        verifyNoInteractions(subscriptionApplicationService);
    }

    // ── helpers ──────────────────────────────────────────────────────

    private void loginAsPlatformAdmin() {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken("admin", "n/a", "ROLE_PLATFORM_ADMIN"));
    }

    private static SubscriptionResponse subscription(String tier, String status) {
        SubscriptionResponse response = new SubscriptionResponse();
        response.setId(7L);
        response.setTenantId(TENANT_ID);
        response.setTier(tier);
        response.setStatus(status);
        response.setEffectiveTier(tier);
        return response;
    }
}
