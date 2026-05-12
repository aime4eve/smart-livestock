package com.smartlivestock.identity.interfaces.admin;

import com.smartlivestock.identity.infrastructure.persistence.SpringDataFarmRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataTenantRepository;
import com.smartlivestock.identity.infrastructure.persistence.SpringDataUserRepository;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Admin Dashboard — 1 endpoint.
 * Platform overview with summary + trends. Phase 1 stub for trends.
 */
@RestController
@RequestMapping("/api/v1/admin/dashboard")
@RequiredArgsConstructor
public class DashboardAdminController {

    private final SpringDataTenantRepository springDataTenantRepository;
    private final SpringDataFarmRepository springDataFarmRepository;
    private final SpringDataUserRepository springDataUserRepository;

    /**
     * GET /api/v1/admin/dashboard
     * Platform overview with summary + trends.
     * Trends are Phase 1 stubs returning empty array.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getDashboard() {
        requirePlatformAdmin();

        long tenantCount = springDataTenantRepository.count();
        long farmCount = springDataFarmRepository.count();
        long userCount = springDataUserRepository.count();

        Map<String, Object> summary = Map.of(
                "tenantCount", tenantCount,
                "farmCount", farmCount,
                "userCount", userCount,
                "deviceCount", 0,
                "activeAlertCount", 0
        );

        // Phase 1 stub: trends are placeholder data
        List<Map<String, Object>> trends = List.of();

        Map<String, Object> data = Map.of(
                "summary", summary,
                "trends", trends
        );
        return ResponseEntity.ok(ApiResponse.ok(data));
    }

    private void requirePlatformAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "未认证");
        }
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
        if (!isAdmin) {
            throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 platform_admin 角色");
        }
    }
}
