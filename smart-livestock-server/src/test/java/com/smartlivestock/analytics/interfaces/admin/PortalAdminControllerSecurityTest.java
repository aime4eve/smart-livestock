package com.smartlivestock.analytics.interfaces.admin;

import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * NIX-416: PortalAdminController gated each endpoint with a hand-written
 * requirePlatformAdmin() call in the method body — the guard only held as
 * long as every future endpoint remembered the call. The class-level
 * @PreAuthorize replaces it (AnalyticsAdminController precedent); these
 * tests keep it from regressing.
 */
class PortalAdminControllerSecurityTest {

    @Test
    void classLevel_requiresPlatformAdminOnly() {
        PreAuthorize annotation = PortalAdminController.class.getAnnotation(PreAuthorize.class);
        assertTrue(annotation != null,
                "Missing class-level @PreAuthorize on PortalAdminController");
        assertEquals("hasRole('PLATFORM_ADMIN')", annotation.value());
    }

    @Test
    void endpoints_haveNoPerMethodOverride() {
        for (Method method : PortalAdminController.class.getDeclaredMethods()) {
            assertTrue(method.getAnnotation(PreAuthorize.class) == null,
                    () -> "Per-method @PreAuthorize would override the class-level guard on "
                            + method.getName());
        }
    }
}
