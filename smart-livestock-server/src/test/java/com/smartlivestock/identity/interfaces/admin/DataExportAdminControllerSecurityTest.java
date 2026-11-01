package com.smartlivestock.identity.interfaces.admin;

import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * NIX-350: data-export job oversight (NIX-325) exposes all tenants' export
 * evidence, so it must be platform-admin only. Guards against the same
 * "no annotation at all" regression fixed alongside AnalyticsAdminController.
 */
class DataExportAdminControllerSecurityTest {

    @Test
    void classLevel_requiresPlatformAdminOnly() {
        PreAuthorize annotation = DataExportAdminController.class.getAnnotation(PreAuthorize.class);
        assertTrue(annotation != null,
                "Missing class-level @PreAuthorize on DataExportAdminController");
        assertEquals("hasRole('PLATFORM_ADMIN')", annotation.value());
    }

    @Test
    void endpoints_haveNoPerMethodOverride() {
        for (Method method : DataExportAdminController.class.getDeclaredMethods()) {
            assertTrue(method.getAnnotation(PreAuthorize.class) == null,
                    () -> "Per-method @PreAuthorize would override the class-level guard on "
                            + method.getName());
        }
    }
}
