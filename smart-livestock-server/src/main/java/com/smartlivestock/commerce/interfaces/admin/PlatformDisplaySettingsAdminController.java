package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.application.service.PlatformDisplaySettingsService;
import com.smartlivestock.commerce.domain.model.LockedTilePolicy;
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
 * Platform-level configuration of the NIX-389 locked-tile presentation
 * policy (V20261107100000). Platform operators only — the policy shapes every
 * tenant's health tiles, so this is deliberately not farm-scoped and not open
 * to B2B admins (same rationale as SubscriptionHealthSettingsAdminController).
 */
@RestController
@RequestMapping("/api/v1/admin/platform/display-settings")
@RequiredArgsConstructor
@PreAuthorize("hasRole('PLATFORM_ADMIN')")
public class PlatformDisplaySettingsAdminController {

    private final PlatformDisplaySettingsService settingsService;

    @GetMapping
    public ResponseEntity<ApiResponse<SettingsDto>> get() {
        requirePlatformAdmin();
        return ResponseEntity.ok(ApiResponse.ok(SettingsDto.from(settingsService.getLockedTilePolicy())));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<SettingsDto>> update(@RequestBody Map<String, Object> body) {
        requirePlatformAdmin();
        Long operatorId = getCurrentUserId();
        String operatorRole = getOperatorRole();
        // Cheap guard before delegating: the service re-validates, but the
        // standalone-MockMvc test surface asserts 400 straight from here.
        Object raw = body.get("lockedTilePolicy");
        if (!(raw instanceof String value) || value.isBlank()) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "commerce.displaySettings.missingField", new Object[]{"lockedTilePolicy"});
        }
        LockedTilePolicy policy = PlatformDisplaySettingsService.parsePolicy(value);
        LockedTilePolicy updated = settingsService.updateLockedTilePolicy(policy, operatorId, operatorRole);
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

    public record SettingsDto(String lockedTilePolicy) {
        static SettingsDto from(LockedTilePolicy policy) {
            return new SettingsDto(policy.name());
        }
    }
}
