package com.smartlivestock.ranch.application.signal;

import com.smartlivestock.identity.domain.repository.UserFarmAssignmentRepository;
import com.smartlivestock.ranch.domain.port.IdentityQueryPort;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.security.ApiKeyAuthFilter;
import com.smartlivestock.shared.security.SwitchedContext;
import com.smartlivestock.shared.tenant.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;

/**
 * Who may read a farm's live signals (map, livestock list and stream ticket).
 *
 * <ul>
 *   <li>farm members: an ACTIVE {@code user_farm_assignments} row — the
 *       original rule;</li>
 *   <li>super-admin switched-context sessions: every farm of the chosen
 *       tenant. The context entry (design 2026-10-19) deliberately creates no
 *       per-farm membership, so these sessions are scoped by tenant, exactly
 *       like {@code /fences} already treats them. Super admins never enter
 *       through the membership branch: their own tokens carry
 *       ROLE_SUPER_ADMIN and stay refused even if a membership row ever
 *       exists for the account.</li>
 * </ul>
 * Everything else — the root super-admin token, a tenant-less PLATFORM_ADMIN
 * context, B2B/platform admins, API keys — stays forbidden.
 */
@Component
@RequiredArgsConstructor
public class SignalFarmAccessPolicy {

    static final String MESSAGE_KEY = "authz.noPermissionFarmSignal";

    private final UserFarmAssignmentRepository userFarmAssignmentRepository;
    private final IdentityQueryPort identityQueryPort;

    /**
     * @throws ApiException AUTH_FORBIDDEN when the caller may not read the farm's signals
     */
    public void requireFarmAccess(Long farmId, Long userId) {
        if (userId == null) {
            throw forbidden();
        }
        // API keys authenticate as api_keys.id — a bare Long that the
        // membership check below would mistake for a user id (the id spaces
        // collide: seeded key 2 vs user 2). Live signals are app-facing;
        // Open API serves key consumers. Same distinction as NIX-337.
        if (isApiKeyRequest()) {
            throw forbidden();
        }
        if (isSuperAdminPrincipal()) {
            // Root super-admin tokens stay refused regardless of membership
            // rows; only a switched context scoped to its tenant reads signals.
            if (SwitchedContext.isCurrent() && farmInCurrentTenant(farmId)) {
                return;
            }
            throw forbidden();
        }
        if (userFarmAssignmentRepository.existsByUserIdAndFarmIdAndStatus(userId, farmId, "ACTIVE")) {
            return;
        }
        if (SwitchedContext.isCurrent() && farmInCurrentTenant(farmId)) {
            return;
        }
        throw forbidden();
    }

    private boolean isApiKeyRequest() {
        RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
        return attributes != null && attributes.getAttribute(
                ApiKeyAuthFilter.ATTR_API_KEY, RequestAttributes.SCOPE_REQUEST) != null;
    }

    private boolean isSuperAdminPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(granted -> "ROLE_SUPER_ADMIN".equals(granted.getAuthority()));
    }

    private boolean farmInCurrentTenant(Long farmId) {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return false;
        }
        // Unknown farms read as forbidden too: no existence leak across tenants.
        return identityQueryPort.findFarmById(farmId)
                .map(farm -> tenantId.equals(farm.tenantId()))
                .orElse(false);
    }

    /** The shared refusal for every caller of this policy (signal endpoints only). */
    public static ApiException forbidden() {
        return new ApiException(ErrorCode.AUTH_FORBIDDEN, MESSAGE_KEY);
    }
}
