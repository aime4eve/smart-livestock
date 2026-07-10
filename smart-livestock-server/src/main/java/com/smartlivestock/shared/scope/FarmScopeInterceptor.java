package com.smartlivestock.shared.scope;

import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.tenant.TenantContext;
import com.smartlivestock.shared.web.FarmIdPathParser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class FarmScopeInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(FarmScopeInterceptor.class);
    private static final String HEADER_ACTIVE_FARM = "x-active-farm";

    private final FarmScopeResolver resolver = new FarmScopeResolver();
    private final SpringDataFarmRepository farmRepository;

    public FarmScopeInterceptor(SpringDataFarmRepository farmRepository) {
        this.farmRepository = farmRepository;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) {
        String uri = request.getRequestURI();

        // Only intercept paths that contain /farms/{farmId}
        Long pathFarmId = FarmIdPathParser.extractFarmId(uri);
        if (pathFarmId == null) {
            return true;
        }

        // Read header
        Long headerFarmId = readHeaderFarmId(request);

        // Determine scope type from HTTP method
        FarmScopeType scopeType = isReadMethod(request.getMethod())
                ? FarmScopeType.READ : FarmScopeType.WRITE;

        // Validate scope (throws on dual-source or write+header-only)
        resolver.resolve(scopeType, pathFarmId, headerFarmId);

        // Validate tenant-farm ownership (skip for platform_admin and Open API)
        if (!isOpenApiPath(uri) && !isPlatformAdmin() && !isApiKeyAuth()) {
            validateFarmBelongsToTenant(pathFarmId);
        }

        // Store resolved farmId for downstream handlers
        request.setAttribute("resolvedFarmId", pathFarmId);

        return true;
    }

    private Long readHeaderFarmId(HttpServletRequest request) {
        String header = request.getHeader(HEADER_ACTIVE_FARM);
        if (header == null || header.isBlank()) {
            return null;
        }
        try {
            return Long.valueOf(header.trim());
        } catch (NumberFormatException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "x-active-farm 格式错误，期望数字");
        }
    }

    private boolean isReadMethod(String method) {
        return "GET".equalsIgnoreCase(method) || "HEAD".equalsIgnoreCase(method)
                || "OPTIONS".equalsIgnoreCase(method);
    }

    private boolean isOpenApiPath(String uri) {
        return uri.contains("/api/v1/open/");
    }

    private boolean isPlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(a -> a.equals("ROLE_PLATFORM_ADMIN"));
    }

    private boolean isApiKeyAuth() {
        // API Key auth doesn't set JWT-based SecurityContext;
        // when TenantContext is null the request is either unauthenticated or API Key authenticated.
        return TenantContext.getCurrentTenant() == null;
    }

    private void validateFarmBelongsToTenant(Long farmId) {
        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) {
            return; // unauthenticated — will be caught by SecurityConfig
        }
        if (!farmRepository.existsByIdAndTenantId(farmId, tenantId)) {
            log.warn("Farm {} does not belong to tenant {}", farmId, tenantId);
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN,
                    "无权访问该牧场");
        }
    }
}
