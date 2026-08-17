package com.smartlivestock.datagen.application;

import com.smartlivestock.datagen.application.DatagenOperatorContext.DatagenOperatorRole;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class DatagenOperatorContextResolver {

    public DatagenOperatorContext resolve() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof Long userId)) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "error.datagen.forbidden");
        }
        boolean platformAdmin = authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_PLATFORM_ADMIN".equals(authority.getAuthority()));
        boolean b2bAdmin = authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_B2B_ADMIN".equals(authority.getAuthority()));
        if (!platformAdmin && !b2bAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.datagen.forbidden");
        }

        Long tenantId = TenantContext.getCurrentTenant();
        if (b2bAdmin && tenantId == null) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "error.datagen.tenantMissing");
        }

        return new DatagenOperatorContext(
                userId, tenantId,
                platformAdmin ? DatagenOperatorRole.PLATFORM_ADMIN : DatagenOperatorRole.B2B_ADMIN);
    }
}
