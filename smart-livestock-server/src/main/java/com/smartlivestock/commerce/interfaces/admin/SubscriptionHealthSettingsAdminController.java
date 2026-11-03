package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsService;
import com.smartlivestock.commerce.application.service.SubscriptionHealthSettingsProvider.HealthThresholds;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Platform-level configuration of the NIX-324 banner tiers (V20261103100000).
 * Platform operators only — the tiers gate every tenant's banner, not one
 * farm's data, so this is deliberately not farm-scoped and not open to
 * B2B admins (unlike DeviceProfileRuleAdminController).
 */
@RestController
@RequestMapping("/api/v1/admin/subscription-health-settings")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class SubscriptionHealthSettingsAdminController {

    private final SubscriptionHealthSettingsService settingsService;

    @GetMapping
    public ResponseEntity<ApiResponse<SettingsDto>> get() {
        requirePlatformAdmin();
        return ResponseEntity.ok(ApiResponse.ok(SettingsDto.from(settingsService.get())));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<SettingsDto>> update(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();
        Long operatorId = getCurrentUserId();
        String operatorRole = getOperatorRole();
        // Cheap guard before delegating: the service re-validates, but the
        // standalone-MockMvc test surface asserts 400 straight from here.
        int warnDays = intValue(body, "warnDays");
        int cautionDays = intValue(body, "cautionDays");
        int dangerDays = intValue(body, "dangerDays");
        if (warnDays <= 0 || cautionDays <= 0 || dangerDays <= 0
                || warnDays <= cautionDays || cautionDays <= dangerDays) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.healthSettings.invalidTiers",
                    new Object[]{warnDays, cautionDays, dangerDays});
        }
        HealthThresholds updated = settingsService.update(
                warnDays, cautionDays, dangerDays, operatorId, operatorRole);
        return ResponseEntity.ok(ApiResponse.ok(SettingsDto.from(updated)));
    }

    /** Explicit in-body guard: standalone MockMvc does not enforce @PreAuthorize. */
    private static void requirePlatformAdmin() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getAuthorities().stream()
                .noneMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"))) {
            throw new AccessDeniedException("platform admin only");
        }
    }

    private static int intValue(Map<String, Object> body, String key) {
        Object value = body.get(key);
        if (value instanceof Number number) return number.intValue();
        if (value == null) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.healthSettings.missingField", new Object[]{key});
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (NumberFormatException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.healthSettings.missingField", new Object[]{key});
        }
    }

    private static Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getPrincipal() == null) {
            throw new ApiException(ErrorCode.AUTH_INVALID_TOKEN, "auth.unauthorized");
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof Number number) return number.longValue();
        return Long.valueOf(principal.toString());
    }

    private static String getOperatorRole() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) return null;
        return authentication.getAuthorities().stream().findFirst()
                .map(Object::toString).orElse(null);
    }

    public record SettingsDto(int warnDays, int cautionDays, int dangerDays) {
        static SettingsDto from(HealthThresholds thresholds) {
            return new SettingsDto(thresholds.warnDays(), thresholds.cautionDays(), thresholds.dangerDays());
        }
    }
}
