package com.smartlivestock.health.interfaces.admin;

import com.smartlivestock.health.application.service.ContactAnalysisScheduler;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Admin-side manual trigger for the resident contact analysis track
 * (plan Task 2, 2026-09-29): runs the exact same rolling re-computation as
 * the daily scheduler so the contact pool can be verified without waiting
 * for 02:00. Not exposed to the app UI; permission model follows the other
 * platform admin controllers (ROLE_PLATFORM_ADMIN).
 */
@RestController
@RequestMapping("/api/v1/admin/contact-analysis")
@RequiredArgsConstructor
public class ContactAnalysisAdminController {

    private final ContactAnalysisScheduler contactAnalysisScheduler;

    /**
     * POST /api/v1/admin/contact-analysis/trigger
     * Whole-herd rolling analysis for every farm; returns the rows written
     * per farm plus the farms that failed (logged, non-blocking).
     */
    @PostMapping("/trigger")
    public ResponseEntity<ApiResponse<Map<String, Object>>> trigger() {
        requirePlatformAdmin();

        ContactAnalysisScheduler.FarmAnalysisOutcome outcome = contactAnalysisScheduler.runForAllFarms();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("writtenByFarm", outcome.writtenByFarm());
        data.put("failedFarms", outcome.failedFarms());
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
