package com.smartlivestock.iot.interfaces.admin;

import com.smartlivestock.iot.application.DeviceProfileRuleService;
import com.smartlivestock.iot.domain.model.DeviceProfileRule;
import com.smartlivestock.iot.domain.model.DeviceType;
import com.smartlivestock.iot.infrastructure.client.thingsboard.TbClient;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * Platform-level CRUD for the TB device profile allowlist (NIX-214).
 * Not farm-scoped: the allowlist is global, managed by platform operators.
 */
@RestController
@RequestMapping("/api/v1/admin/device-profile-rules")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")
public class DeviceProfileRuleAdminController {

    private final DeviceProfileRuleService ruleService;
    private final TbClient tbClient;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RuleDto>>> list() {
        return ResponseEntity.ok(ApiResponse.ok(ruleService.list().stream()
                .map(RuleDto::from).toList()));
    }

    @GetMapping("/tb-profiles")
    public ResponseEntity<ApiResponse<List<TbProfileDto>>> tbProfiles() {
        try {
            List<TbProfileDto> profiles = tbClient.fetchDeviceProfiles().entrySet().stream()
                    .map(entry -> new TbProfileDto(entry.getKey(), entry.getValue()))
                    .sorted(java.util.Comparator.comparing(TbProfileDto::name))
                    .toList();
            return ResponseEntity.ok(ApiResponse.ok(profiles));
        } catch (Exception e) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR,
                    "iot.tb.profilesUnavailable", new Object[]{});
        }
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RuleDto>> create(@RequestBody Map<String, Object> body) {
        RuleDto created = RuleDto.from(ruleService.create(
                (String) body.get("profileName"),
                parseDeviceType(body.get("deviceType")),
                parseEnabled(body.get("enabled")),
                (String) body.get("remark"),
                getCurrentUserId()));
        return ResponseEntity.ok(ApiResponse.ok(created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RuleDto>> update(
            @PathVariable Long id, @RequestBody Map<String, Object> body) {
        RuleDto updated = RuleDto.from(ruleService.update(
                id,
                parseDeviceType(body.get("deviceType")),
                parseEnabled(body.get("enabled")),
                (String) body.get("remark"),
                getCurrentUserId()));
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> delete(@PathVariable Long id) {
        ruleService.delete(id, getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("deleted", true)));
    }

    private static DeviceType parseDeviceType(Object value) {
        if (value == null || value.toString().isBlank()) return null;
        try {
            return DeviceType.valueOf(value.toString().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ApiException(ErrorCode.VALIDATION_ERROR,
                    "iot.profileRule.invalidDeviceType", new Object[]{});
        }
    }

    private static boolean parseEnabled(Object value) {
        if (value instanceof Boolean b) return b;
        // Absent field means "create enabled": the column default is TRUE and
        // an allowlist entry that is created disabled is never what callers
        // mean (it silently breaks the preflight allowlist match).
        if (value == null) return true;
        return Boolean.parseBoolean(value.toString());
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

    public record RuleDto(Long id, String profileName, String deviceType,
                          boolean enabled, String remark, java.time.Instant updatedAt) {
        static RuleDto from(DeviceProfileRule rule) {
            return new RuleDto(rule.getId(), rule.getProfileName(),
                    rule.getDeviceType() == null ? null : rule.getDeviceType().name(),
                    rule.isEnabled(), rule.getRemark(), rule.getUpdatedAt());
        }
    }

    public record TbProfileDto(String id, String name) {}
}
