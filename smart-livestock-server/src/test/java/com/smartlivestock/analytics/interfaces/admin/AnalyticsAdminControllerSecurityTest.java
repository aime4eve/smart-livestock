package com.smartlivestock.analytics.interfaces.admin;

import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * NIX-350: the admin analytics controller historically had no guard at all
 * (any logged-in role could read platform-wide usage data). The class-level
 * @PreAuthorize is the fix — these tests keep it from regressing.
 */
class AnalyticsAdminControllerSecurityTest {

    @Test
    void classLevel_requiresPlatformAdminOnly() {
        PreAuthorize annotation = AnalyticsAdminController.class.getAnnotation(PreAuthorize.class);
        assertTrue(annotation != null,
                "Missing class-level @PreAuthorize on AnalyticsAdminController");
        assertEquals("hasRole('PLATFORM_ADMIN')", annotation.value());
    }

    @Test
    void endpoints_haveNoPerMethodOverride() {
        for (Method method : AnalyticsAdminController.class.getDeclaredMethods()) {
            assertTrue(method.getAnnotation(PreAuthorize.class) == null,
                    () -> "Per-method @PreAuthorize would override the class-level guard on "
                            + method.getName());
        }
    }
}
