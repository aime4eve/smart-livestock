package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class DatagenOperatorContextResolverTest {
    private final DatagenOperatorContextResolver resolver = new DatagenOperatorContextResolver();

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
        TenantContext.clear();
    }

    @Test
    void resolve_platformAdminWithoutTenant_succeeds() {
        authenticate("ROLE_PLATFORM_ADMIN");

        DatagenOperatorContext context = resolver.resolve();

        assertEquals(1L, context.userId());
        assertEquals(null, context.tenantId());
        assertEquals(DatagenOperatorRole.PLATFORM_ADMIN, context.role());
    }

    @Test
    void resolve_b2bAdminWithoutTenant_rejects() {
        authenticate("ROLE_B2B_ADMIN");

        ApiException ex = assertThrows(ApiException.class, resolver::resolve);
        assertEquals(ErrorCode.AUTH_FORBIDDEN, ex.getCode());
    }

    @Test
    void resolve_b2bAdminWithTenant_succeeds() {
        authenticate("ROLE_B2B_ADMIN");
        TenantContext.setCurrentTenant(7L);

        DatagenOperatorContext context = resolver.resolve();

        assertEquals(7L, context.tenantId());
        assertEquals(DatagenOperatorRole.B2B_ADMIN, context.role());
    }

    @Test
    void resolve_nonAdmin_rejects() {
        authenticate("ROLE_OWNER");
        TenantContext.setCurrentTenant(7L);

        ApiException ex = assertThrows(ApiException.class, resolver::resolve);
        assertEquals(ErrorCode.AUTH_FORBIDDEN, ex.getCode());
    }

    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(
                new TestingAuthenticationToken(1L, null, role));
    }
}
