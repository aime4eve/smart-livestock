package com.smartlivestock.commerce.interfaces.admin;

import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * NIX-416: the all-tenant subscription health overview shipped (NIX-324,
 * spec §4.2 "platform_admin only") with NO guard at all — any logged-in
 * role could enumerate every tenant's subscription state, expiry dates and
 * export windows. The class-level @PreAuthorize is the fix; these tests
 * keep it from regressing (AnalyticsAdminControllerSecurityTest precedent).
 */
class AdminSubscriptionOverviewControllerSecurityTest {

    @Test
    void classLevel_requiresPlatformAdminOnly() {
        PreAuthorize annotation =
                AdminSubscriptionOverviewController.class.getAnnotation(PreAuthorize.class);
        assertTrue(annotation != null,
                "Missing class-level @PreAuthorize on AdminSubscriptionOverviewController");
        assertEquals("hasRole('PLATFORM_ADMIN')", annotation.value());
    }

    @Test
    void endpoints_haveNoPerMethodOverride() {
        for (Method method : AdminSubscriptionOverviewController.class.getDeclaredMethods()) {
            assertTrue(method.getAnnotation(PreAuthorize.class) == null,
                    () -> "Per-method @PreAuthorize would override the class-level guard on "
                            + method.getName());
        }
    }
}
