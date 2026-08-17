package com.smartlivestock.datagen.interfaces.admin;

import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;
import java.util.Arrays;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DataGenControllerSecurityTest {
    @Test
    void legacyGlobalEndpoints_requirePlatformAdminOnly() {
        for (Method method : DataGenAdminController.class.getDeclaredMethods()) {
            PreAuthorize annotation = method.getAnnotation(PreAuthorize.class);
            assertTrue(annotation != null,
                    () -> "Missing @PreAuthorize on " + method.getName());
            assertEquals("hasRole('PLATFORM_ADMIN')", annotation.value(),
                    () -> "Wrong role on " + method.getName());
        }
    }

    @Test
    void consoleController_allowsPlatformAndB2bAdmin() {
        PreAuthorize annotation = DataGenConsoleController.class.getAnnotation(PreAuthorize.class);
        assertTrue(annotation != null);
        assertEquals("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')", annotation.value());
    }
}
