package com.smartlivestock.commerce.interfaces.admin;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.infrastructure.persistence.SpringDataFeatureGateRepository;
import com.smartlivestock.commerce.infrastructure.persistence.mapper.FeatureGateMapper;
import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ApiResponse;
import com.smartlivestock.shared.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Admin feature-gate management — 2 endpoints.
 * All operations require platform_admin role.
 */
@RestController
@RequestMapping("/api/v1/admin/feature-gates")
@RequiredArgsConstructor
public class AdminFeatureGateController {

    private final SpringDataFeatureGateRepository springDataFeatureGateRepository;

    /**
     * GET /api/v1/admin/feature-gates
     * List all feature gates.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> listFeatureGates() {
        requirePlatformAdmin();

        List<Map<String, Object>> items = springDataFeatureGateRepository.findAll().stream()
                .map(FeatureGateMapper::toDomain)
                .map(this::toGateMap)
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(items));
    }

    /**
     * PUT /api/v1/admin/feature-gates/{id}
     * Update feature gate configuration.
     */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateFeatureGate(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        requirePlatformAdmin();

        var existing = springDataFeatureGateRepository.findById(id)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND,
                        "Feature gate not found: " + id));

        if (body.containsKey("limitValue")) {
            existing.setLimitValue(((Number) body.get("limitValue")).intValue());
        }
        if (body.containsKey("retentionDays")) {
            existing.setRetentionDays(((Number) body.get("retentionDays")).intValue());
        }
        if (body.containsKey("isEnabled")) {
            existing.setIsEnabled(Boolean.parseBoolean(body.get("isEnabled").toString()));
        }

        springDataFeatureGateRepository.save(existing);
        return ResponseEntity.ok(ApiResponse.ok(toGateMap(FeatureGateMapper.toDomain(existing))));
    }

    // ── Helpers ────────────────────────────────────────────────────

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

    private Map<String, Object> toGateMap(FeatureGate gate) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", gate.getId());
        m.put("tier", gate.getTier());
        m.put("featureKey", gate.getFeatureKey());
        m.put("gateType", gate.getGateType() != null ? gate.getGateType().name() : null);
        m.put("limitValue", gate.getLimitValue());
        m.put("retentionDays", gate.getRetentionDays());
        m.put("isEnabled", gate.isEnabled());
        return m;
    }
}
